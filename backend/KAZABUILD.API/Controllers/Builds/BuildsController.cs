using KAZABUILD.Application.DTOs.Builds.Build;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Application.DTOs.Components.Components.CPUComponent;
using KAZABUILD.Application.DTOs.Components.Components.GPUComponent;
using KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent;
using KAZABUILD.Application.DTOs.Components.Components.MemoryComponent;
using KAZABUILD.Application.DTOs.Components.Components.StorageComponent;
using KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent;
using KAZABUILD.Application.DTOs.Components.Components.CoolerComponent;
using KAZABUILD.Application.DTOs.Components.Components.CaseComponent;
using KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent;
using KAZABUILD.Application.DTOs.Components.Components.MonitorComponent;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Builds
{
    /// <summary>
    /// Controller for Build related endpoints.
    /// The users, administration and the system can all send them.
    /// Includes protections for different statuses.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class BuildsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new Build.
        /// Used to create a draft of the build for users.
        /// Admins can create any status.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddBuild([FromBody] CreateBuildDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the user exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Build",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has admin permissions or if they are creating a build for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Build",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a build to add
            Build build = new()
            {
                UserId = dto.UserId,
                Name = dto.Name,
                Description = dto.Description,
                Status = isPrivileged ? dto.Status : BuildStatus.DRAFT,
                PublishedAt = isPrivileged && dto.Status != BuildStatus.DRAFT ? dto.PublishedAt : null,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the build to the database
            _db.Builds.Add(build);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Build",
                ip,
                build.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Build Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.created", new
            {
                buildId = build.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { build = "Build sent successfully!", id = build.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected Build.
        /// User can modify all fields as well as transfer ownership.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateBuild(Guid id, [FromBody] UpdateBuildDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the build to edit
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == id);
            //Check if the build exists
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Build",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Build"
                );

                //Return not found response
                return NotFound(new { build = "Build not found!" });
            }

            //Check if current user has admin permissions or if they are modifying their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == build.UserId;

            //Return unauthorized access exception if the user does not have the correct permissions
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return forbidden response
                return Forbid();
            }

            //Check if the user isn't modifying an auto-generated build
            if (!isPrivileged && build.Status == BuildStatus.GENERATED)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Users cannot modify auto-generated builds!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.UserId != null)
            {
                changedFields.Add("UserId: " + build.UserId);

                build.UserId = (Guid)dto.UserId;
            }
            if (!string.IsNullOrWhiteSpace(dto.Description))
            {
                changedFields.Add("Description: " + build.Description);

                build.Description = dto.Description;
            }
            if (!string.IsNullOrWhiteSpace(dto.Name))
            {
                changedFields.Add("Name: " + build.Name);

                build.Name = dto.Name;
            }
            if (dto.Status != null && dto.Status != build.Status && (dto.Status == BuildStatus.DRAFT || dto.Status == BuildStatus.PUBLISHED || isPrivileged))
            {
                changedFields.Add("Status: " + build.Status);

                build.Status = (BuildStatus)dto.Status;

                if(dto.Status == BuildStatus.PUBLISHED)
                {
                    changedFields.Add("PublishedAt: " + build.PublishedAt);

                    build.PublishedAt = isPrivileged && dto.PublishedAt != null ? dto.PublishedAt : DateTime.UtcNow;
                }
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + build.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        build.Note = null;
                    else
                        build.Note = dto.Note;
                }
            }

            //Update edit timestamp
            build.LastEditedAt = DateTime.UtcNow;

            //Update the build
            _db.Builds.Update(build);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Build",
                ip,
                build.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.updated", new
            {
                buildId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { build = "Build updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Build specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BuildResponseDto>> GetBuild(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Get the build to return with all necessary includes
            var build = await _db.Builds
                .AsNoTracking()
                .Include(b => b.User)
                .Include(b => b.Tags)
                .Include(b => b.Components)
                    .ThenInclude(c => c.Component)
                .Include(b => b.Interactions)
                .Include(b => b.Images)
                .FirstOrDefaultAsync(b => b.Id == id);
                
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Build",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Build"
                );

                //Return not found response
                return NotFound(new { build = "Build not found!" });
            }

            //Check if current user is getting themselves or if they have admin permissions
            var isSelf = currentUserId == build.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged && (build.Status == BuildStatus.DRAFT || build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Build",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Calculate rating information for this build
            var ratings = await _db.BuildInteractions
                .Where(i => i.BuildId == id && i.Rating != null && i.Rating > 0)
                .GroupBy(i => i.BuildId)
                .Select(g => new
                {
                    BuildId = g.Key,
                    Average = g.Average(i => (double)i.Rating!) / 20.0, // Convert 0-100 to 0-5
                    Count = g.Count()
                })
                .FirstOrDefaultAsync();

            var avgRating = ratings?.Average ?? 0.0;
            var ratingsCount = ratings?.Count ?? 0;

            //Get user rating for current user
            var userRatingRecord = await _db.BuildInteractions
                .Where(i => i.BuildId == id && i.UserId == currentUserId && i.Rating != null && i.Rating > 0)
                .FirstOrDefaultAsync();
            var userRating = userRatingRecord != null ? (double?)userRatingRecord.Rating / 20.0 : null;

            //Helper method to map component to DTO (same as in GetBuilds)
            BaseComponentResponseDto? MapComponent(BaseComponent? component)
            {
                if (component == null) return null;
                return component switch
                {
                    CPUComponent cpu => new CPUComponentResponseDto
                    {
                        Id = cpu.Id,
                        Name = cpu.Name,
                        Type = cpu.Type,
                        Manufacturer = cpu.Manufacturer,
                    },
                    GPUComponent gpu => new GPUComponentResponseDto
                    {
                        Id = gpu.Id,
                        Name = gpu.Name,
                        Type = gpu.Type,
                        Manufacturer = gpu.Manufacturer,
                    },
                    MotherboardComponent mb => new MotherboardComponentResponseDto
                    {
                        Id = mb.Id,
                        Name = mb.Name,
                        Type = mb.Type,
                        Manufacturer = mb.Manufacturer,
                    },
                    MemoryComponent ram => new MemoryComponentResponseDto
                    {
                        Id = ram.Id,
                        Name = ram.Name,
                        Type = ram.Type,
                        Manufacturer = ram.Manufacturer,
                    },
                    StorageComponent storage => new StorageComponentResponseDto
                    {
                        Id = storage.Id,
                        Name = storage.Name,
                        Type = storage.Type,
                        Manufacturer = storage.Manufacturer,
                    },
                    PowerSupplyComponent psu => new PowerSupplyComponentResponseDto
                    {
                        Id = psu.Id,
                        Name = psu.Name,
                        Type = psu.Type,
                        Manufacturer = psu.Manufacturer,
                    },
                    CoolerComponent cooler => new CoolerComponentResponseDto
                    {
                        Id = cooler.Id,
                        Name = cooler.Name,
                        Type = cooler.Type,
                        Manufacturer = cooler.Manufacturer,
                    },
                    CaseComponent pcCase => new CaseComponentResponseDto
                    {
                        Id = pcCase.Id,
                        Name = pcCase.Name,
                        Type = pcCase.Type,
                        Manufacturer = pcCase.Manufacturer,
                    },
                    CaseFanComponent fan => new CaseFanComponentResponseDto
                    {
                        Id = fan.Id,
                        Name = fan.Name,
                        Type = fan.Type,
                        Manufacturer = fan.Manufacturer,
                    },
                    MonitorComponent monitor => new MonitorComponentResponseDto
                    {
                        Id = monitor.Id,
                        Name = monitor.Name,
                        Type = monitor.Type,
                        Manufacturer = monitor.Manufacturer,
                    },
                    _ => null
                };
            }

            //Map components
            var components = build.Components?
                .Where(bc => bc.Component != null)
                .Select(bc => MapComponent(bc.Component))
                .Where(c => c != null)
                .Cast<BaseComponentResponseDto>()
                .ToList() ?? new List<BaseComponentResponseDto>();

            //Map tags
            var tags = build.Tags?.Select(t => t.Name).ToList() ?? new List<string>();
            
            // Debug logging for tags
            System.Diagnostics.Debug.WriteLine($"GetBuild: Build {build.Id} has {tags.Count} tags: {string.Join(", ", tags)}");

            //Get build image (first BUILD type image)
            var buildImage = build.Images?.FirstOrDefault(img => img.LocationType == ImageLocationType.BUILD);
            var imageUrl = buildImage?.Id.ToString();

            //Get author information
            var authorName = build.User?.DisplayName ?? build.User?.Login ?? "Unknown";
            var authorImageId = build.User?.ImageId;

            //Log Description string declaration
            string logDescription;

            //Create build response with all necessary information
            BuildResponseDto response;
            
            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create build response
                response = new BuildResponseDto
                {
                    Id = build.Id,
                    UserId = build.UserId,
                    Name = build.Name,
                    Description = build.Description,
                    Status = build.Status,
                    PublishedAt = build.PublishedAt,
                    // Additional fields for build detail page
                    Components = components,
                    Tags = tags,
                    AverageRating = avgRating,
                    RatingsCount = ratingsCount,
                    UserRating = userRating,
                    AuthorName = authorName,
                    AuthorImageId = authorImageId,
                    ImageUrl = imageUrl
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create build response
                response = new BuildResponseDto
                {
                    Id = build.Id,
                    UserId = build.UserId,
                    Name = build.Name,
                    Description = build.Description,
                    Status = build.Status,
                    PublishedAt = build.PublishedAt,
                    DatabaseEntryAt = build.DatabaseEntryAt,
                    LastEditedAt = build.LastEditedAt,
                    Note = build.Note,
                    // Additional fields for build detail page
                    Components = components,
                    Tags = tags,
                    AverageRating = avgRating,
                    RatingsCount = ratingsCount,
                    UserRating = userRating,
                    AuthorName = authorName,
                    AuthorImageId = authorImageId,
                    ImageUrl = imageUrl
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Build",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.got", new
            {
                buildId = id,
                gotBy = currentUserId
            });

            //Return the build
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Builds with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BuildResponseDto>>> GetBuilds([FromBody] GetBuildDto dto)
        {
            //Get build id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Start with base query and apply security filter first
            var baseQuery = _db.Builds.AsNoTracking()
                .Where(b => b.UserId == currentUserId || isPrivileged || (b.Status != BuildStatus.DRAFT && b.Status != BuildStatus.GENERATED));

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                baseQuery = baseQuery.Where(b => dto.UserId.Contains(b.UserId));
            }
            if (dto.Name != null)
            {
                baseQuery = baseQuery.Where(b => dto.Name.Contains(b.Name));
            }
            if (dto.Status != null)
            {
                baseQuery = baseQuery.Where(b => dto.Status.Contains(b.Status));
            }
            if (dto.Tag != null)
            {
                baseQuery = baseQuery.Include(b => b.Tags).Where(b => b.Tags.Any(t => dto.Tag.Contains(t.Name)));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                baseQuery = baseQuery.Include(b => b.User).Search(dto.Query, b => b.Name, b => b.Status, b => b.Description, b => b.User!.DisplayName);
            }

            //Order by specified field if provided, otherwise use default sorting by DatabaseEntryAt descending
            IQueryable<Build> orderedQuery = baseQuery;
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                orderedQuery = baseQuery.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }
            else
            {
                // Default sorting: newest builds first (PublishedAt descending, then DatabaseEntryAt)
                // Published builds should be sorted by PublishedAt, drafts by DatabaseEntryAt
                orderedQuery = baseQuery
                    .OrderByDescending(b => b.PublishedAt ?? b.DatabaseEntryAt);
            }

            //Get builds with paging
            IQueryable<Build> pagedQuery = orderedQuery;
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                pagedQuery = orderedQuery
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Now apply includes for the final query
            var query = pagedQuery
                .Include(b => b.User)
                .Include(b => b.Tags)
                .Include(b => b.Components)
                    .ThenInclude(c => c.Component)
                .Include(b => b.Interactions)
                .Include(b => b.Images);

            //Log Description string declaration
            string logDescription;

            List<Build> builds = await query.ToListAsync();

            //Calculate ratings for all builds
            var buildIds = builds.Select(b => b.Id).ToList();
            
            System.Diagnostics.Debug.WriteLine($"GetBuilds: Calculating ratings for {buildIds.Count} builds");
            
            var allInteractions = await _db.BuildInteractions
                .Where(i => buildIds.Contains(i.BuildId))
                .ToListAsync();
            
            System.Diagnostics.Debug.WriteLine($"GetBuilds: Found {allInteractions.Count} total interactions");
            System.Diagnostics.Debug.WriteLine($"GetBuilds: Interactions with ratings: {allInteractions.Count(i => i.Rating != null && i.Rating > 0)}");
            
            var ratings = allInteractions
                .Where(i => i.Rating != null && i.Rating > 0)
                .GroupBy(i => i.BuildId)
                .Select(g => new
                {
                    BuildId = g.Key,
                    Average = g.Average(i => (double)i.Rating!) / 20.0, // Convert 0-100 to 0-5
                    Count = g.Count()
                })
                .ToDictionary(r => r.BuildId, r => new { r.Average, r.Count });

            System.Diagnostics.Debug.WriteLine($"GetBuilds: Calculated ratings for {ratings.Count} builds");
            foreach (var rating in ratings.Take(5))
            {
                System.Diagnostics.Debug.WriteLine($"GetBuilds: Build {rating.Key}: Average={rating.Value.Average:F2}, Count={rating.Value.Count}");
            }

            //Get user ratings for current user (nullable dictionary)
            var userRatingsDict = allInteractions
                .Where(i => i.UserId == currentUserId && i.Rating != null && i.Rating > 0)
                .ToDictionary(i => i.BuildId, i => (double)i.Rating! / 20.0); // Convert 0-100 to 0-5
                
            System.Diagnostics.Debug.WriteLine($"GetBuilds: Found {userRatingsDict.Count} user ratings for current user");

            //Helper method to map component to DTO (simplified version)
            BaseComponentResponseDto? MapComponent(BaseComponent? component)
            {
                if (component == null) return null;
                return component switch
                {
                    CPUComponent cpu => new CPUComponentResponseDto
                    {
                        Id = cpu.Id,
                        Name = cpu.Name,
                        Type = cpu.Type,
                        Manufacturer = cpu.Manufacturer,
                    },
                    GPUComponent gpu => new GPUComponentResponseDto
                    {
                        Id = gpu.Id,
                        Name = gpu.Name,
                        Type = gpu.Type,
                        Manufacturer = gpu.Manufacturer,
                    },
                    MotherboardComponent mb => new MotherboardComponentResponseDto
                    {
                        Id = mb.Id,
                        Name = mb.Name,
                        Type = mb.Type,
                        Manufacturer = mb.Manufacturer,
                    },
                    MemoryComponent ram => new MemoryComponentResponseDto
                    {
                        Id = ram.Id,
                        Name = ram.Name,
                        Type = ram.Type,
                        Manufacturer = ram.Manufacturer,
                    },
                    StorageComponent storage => new StorageComponentResponseDto
                    {
                        Id = storage.Id,
                        Name = storage.Name,
                        Type = storage.Type,
                        Manufacturer = storage.Manufacturer,
                    },
                    PowerSupplyComponent psu => new PowerSupplyComponentResponseDto
                    {
                        Id = psu.Id,
                        Name = psu.Name,
                        Type = psu.Type,
                        Manufacturer = psu.Manufacturer,
                    },
                    CoolerComponent cooler => new CoolerComponentResponseDto
                    {
                        Id = cooler.Id,
                        Name = cooler.Name,
                        Type = cooler.Type,
                        Manufacturer = cooler.Manufacturer,
                    },
                    CaseComponent pcCase => new CaseComponentResponseDto
                    {
                        Id = pcCase.Id,
                        Name = pcCase.Name,
                        Type = pcCase.Type,
                        Manufacturer = pcCase.Manufacturer,
                    },
                    CaseFanComponent fan => new CaseFanComponentResponseDto
                    {
                        Id = fan.Id,
                        Name = fan.Name,
                        Type = fan.Type,
                        Manufacturer = fan.Manufacturer,
                    },
                    MonitorComponent monitor => new MonitorComponentResponseDto
                    {
                        Id = monitor.Id,
                        Name = monitor.Name,
                        Type = monitor.Type,
                        Manufacturer = monitor.Manufacturer,
                    },
                    _ => null
                };
            }

            //Declare response variable
            List<BuildResponseDto> responses;

            //Check what permissions user has and return respective information
            logDescription = isPrivileged 
                ? "Successful Operation - Admin Access, Multiple Builds"
                : "Successful Operation - User Access, Multiple Builds";

            //Create a build response list with all necessary information
            responses = builds.Select(build =>
            {
                //Get rating information
                var ratingInfo = ratings.GetValueOrDefault(build.Id);
                var avgRating = ratingInfo?.Average ?? 0.0;
                var ratingsCount = ratingInfo?.Count ?? 0;
                var userRating = userRatingsDict.ContainsKey(build.Id) 
                    ? (double?)userRatingsDict[build.Id] 
                    : null;
                
                // Debug logging for first few builds
                if (build.Id == builds.FirstOrDefault()?.Id)
                {
                    System.Diagnostics.Debug.WriteLine($"GetBuilds: Build {build.Id} ({build.Name}): Avg={avgRating:F2}, Count={ratingsCount}, UserRating={(userRating?.ToString("F2") ?? "null")}");
                }

                //Get build image (first BUILD type image)
                var buildImage = build.Images?.FirstOrDefault(img => img.LocationType == ImageLocationType.BUILD);
                var imageUrl = buildImage?.Id.ToString();

                //Map components
                var components = build.Components?
                    .Where(bc => bc.Component != null)
                    .Select(bc => MapComponent(bc.Component!))
                    .Where(c => c != null)
                    .Cast<BaseComponentResponseDto>()
                    .ToList() ?? new List<BaseComponentResponseDto>();

                //Map tags
                var tags = build.Tags?.Select(t => t.Name).ToList() ?? new List<string>();
                
                // Debug logging for tags
                if (build.Id == builds.FirstOrDefault()?.Id)
                {
                    System.Diagnostics.Debug.WriteLine($"GetBuilds: Build {build.Id} has {tags.Count} tags: {string.Join(", ", tags)}");
                }

                //Get author information
                var authorName = build.User?.DisplayName ?? build.User?.Login ?? "Unknown";
                var authorImageId = build.User?.ImageId;

                var response = new BuildResponseDto
                {
                    Id = build.Id,
                    UserId = build.UserId,
                    Name = build.Name,
                    Description = build.Description,
                    Status = build.Status,
                    PublishedAt = build.PublishedAt,
                    // DatabaseEntryAt is needed for sorting, so return it for all users
                    DatabaseEntryAt = build.DatabaseEntryAt,
                    LastEditedAt = isPrivileged ? build.LastEditedAt : null,
                    Note = isPrivileged ? build.Note : null,
                    // Additional fields for explore builds page
                    Components = components,
                    Tags = tags,
                    AverageRating = avgRating,
                    RatingsCount = ratingsCount,
                    UserRating = userRating,
                    AuthorName = authorName,
                    AuthorImageId = authorImageId,
                    ImageUrl = imageUrl
                };
                return response;
            }).ToList();

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Build",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.gotBuilds", new
            {
                buildIds = builds.Select(b => b.Id),
                gotBy = currentUserId
            });

            //Return the builds
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Build.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteBuild(Guid id)
        {
            //Get build id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the build to delete
            var build = await _db.Builds.Include(b => b.Images).Include(b => b.Comments).FirstOrDefaultAsync(b => b.Id == id);
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Build",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Build"
                );

                //Return not found response
                return NotFound(new { build = "Build not found!" });
            }

            //Check if current user has admin permissions or if they are deleting their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == build.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Build",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Remove all related images
            if (build.Images.Count != 0)
            {
                foreach (var image in build.Images)
                {
                    //Remove the file from the file system
                    if (System.IO.File.Exists(image.Location))
                        System.IO.File.Delete(image.Location);
                }

                //Delete all related images
                _db.Images.RemoveRange(build.Images);
            }

            //Remove all related comments
            if (build.Comments.Count != 0)
            {
                _db.UserComments.RemoveRange(build.Comments);
            }

            //Handle deleting build tags to avoid conflicts with cascade deletes
            //Get all tags
            var tags = await _db.BuildTags.Where(f => f.BuildId == build.Id).ToListAsync();

            //Remove all compatibilities containing the component id of the component to be deleted
            if (tags.Count != 0)
            {
                _db.BuildTags.RemoveRange(tags);
            }

            //Delete the build
            _db.Builds.Remove(build);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Build",
                ip,
                build.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.deleted", new
            {
                buildId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { build = "Build deleted successfully!" });
        }
    }
}
