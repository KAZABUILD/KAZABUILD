using KAZABUILD.Application.DTOs.Builds.BuildInteraction;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
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
    /// Controller for BuildInteraction related endpoints.
    /// Allows users to interact with public builds.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class BuildInteractionsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new BuildInteraction.
        /// Used to mark that a user interacted with a build.
        /// Users can mark their own interactions, while admins can mark them for all.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddBuildInteraction([FromBody] CreateBuildInteractionDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the build exists
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == dto.BuildId);
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Build Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Build not found!" });
            }

            //Check if the user exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if the user hadn't already interacted with this component
            var interaction = await _db.BuildInteractions.FirstOrDefaultAsync(i => i.UserId == dto.UserId && i.BuildId == dto.BuildId);
            if (interaction != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Build Already Interacted With"
                );

                //Return proper error response
                return BadRequest(new { message = "Interaction already exists!" });
            }

            //Check if current user has admin permissions, is interacting as themselves or if they are adding an interaction to their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;
            var ownBuild = currentUserId == build.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the user isn't interacting with a private build
            if (!isPrivileged && !ownBuild && (build.Status == BuildStatus.DRAFT || build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Build is not public!" });
            }

            //Create a buildInteraction to add
            BuildInteraction buildInteraction = new()
            {
                BuildId = dto.BuildId,
                UserId = dto.UserId,
                IsLiked = dto.IsLiked,
                IsWishlisted = dto.IsWishlisted,
                Rating = dto.Rating,
                UserNote = dto.UserNote,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the buildInteraction to the database
            _db.BuildInteractions.Add(buildInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "BuildInteraction",
                ip,
                buildInteraction.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New BuildInteraction Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildInteraction.created", new
            {
                buildInteractionId = buildInteraction.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { buildInteraction = "BuildInteraction created successfully!", id = buildInteraction.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected BuildInteraction's quantity.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateBuildInteraction(Guid id, [FromBody] UpdateBuildInteractionDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildInteraction to edit
            var buildInteraction = await _db.BuildInteractions.Include(c => c.Build).FirstOrDefaultAsync(i => i.Id == id);

            //Check if the buildInteraction exists
            if (buildInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "BuildInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildInteraction"
                );

                //Return not found response
                return NotFound(new { buildInteraction = "BuildInteraction not found!" });
            }

            //Check if the build was deleted
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == buildInteraction.BuildId);
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    "Operation Failed - Build Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Build not found!" });
            }

            //Check if current user is modifying their own build, is interacting as themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildInteraction.UserId;
            var ownBuild = currentUserId == build.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the user isn't interacting with a private build
            if (!isPrivileged && !ownBuild && (build.Status == BuildStatus.DRAFT || build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Build is not public!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.IsWishlisted != null)
            {
                changedFields.Add("Quantity: " + buildInteraction.IsWishlisted);

                buildInteraction.IsWishlisted = (bool)dto.IsWishlisted;
            }
            if (dto.IsLiked != null)
            {
                changedFields.Add("IsLiked: " + buildInteraction.IsLiked);

                buildInteraction.IsLiked = (bool)dto.IsLiked;
            }
            if (dto.Rating != null)
            {
                changedFields.Add("Rating: " + buildInteraction.Rating);

                buildInteraction.Rating = (int)dto.Rating;
            }
            if (dto.UserNote != null)
            {
                changedFields.Add("UserNote: " + buildInteraction.UserNote);

                if (string.IsNullOrWhiteSpace(dto.UserNote))
                    buildInteraction.UserNote = null;
                else
                    buildInteraction.UserNote = dto.UserNote;
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + buildInteraction.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        buildInteraction.Note = null;
                    else
                        buildInteraction.Note = dto.Note;
                }
            }

            //Update edit timestamp
            buildInteraction.LastEditedAt = DateTime.UtcNow;

            //Update the buildInteraction
            _db.BuildInteractions.Update(buildInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "BuildInteraction",
                ip,
                buildInteraction.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildInteraction.updated", new
            {
                buildInteractionId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildInteraction = "BuildInteraction updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the BuildInteraction specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BuildInteractionResponseDto>> GetBuildInteraction(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildInteraction to return
            var buildInteraction = await _db.BuildInteractions.Include(i => i.Build).FirstOrDefaultAsync(i => i.Id == id);
            if (buildInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildInteraction"
                );

                //Return not found response
                return NotFound(new { buildInteraction = "BuildInteraction not found!" });
            }

            //Check if the build was deleted
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == buildInteraction.BuildId);

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            BuildInteractionResponseDto response;

            //Check if current user is getting their own build, is interacting as themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildInteraction.UserId;
            var ownBuild = build != null && currentUserId == build.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isPrivileged && !isSelf && !ownBuild && (build == null || build.Status == BuildStatus.DRAFT || build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if has admin privilege
            if (isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create buildInteraction response
                response = new BuildInteractionResponseDto
                {
                    Id = buildInteraction.Id,
                    BuildId = buildInteraction.BuildId,
                    UserId = buildInteraction.UserId,
                    IsLiked = buildInteraction.IsLiked,
                    IsWishlisted = buildInteraction.IsWishlisted,
                    Rating = buildInteraction.Rating,
                    UserNote = buildInteraction.UserNote,
                    DatabaseEntryAt = buildInteraction.DatabaseEntryAt,
                    LastEditedAt = buildInteraction.LastEditedAt,
                    Note = buildInteraction.Note,
                };
            }
            else if (isSelf)
            {
                //Change log description
                logDescription = "Successful Operation - Private Access";

                //Create buildInteraction response
                response = new BuildInteractionResponseDto
                {
                    Id = buildInteraction.Id,
                    BuildId = buildInteraction.BuildId,
                    UserId = buildInteraction.UserId,
                    IsLiked = buildInteraction.IsLiked,
                    IsWishlisted = buildInteraction.IsWishlisted,
                    Rating = buildInteraction.Rating,
                    UserNote = buildInteraction.UserNote
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Public Access";

                //Create buildInteraction response
                response = new BuildInteractionResponseDto
                {
                    Id = buildInteraction.Id,
                    BuildId = buildInteraction.BuildId,
                    IsLiked = buildInteraction.IsLiked,
                    IsWishlisted = buildInteraction.IsWishlisted,
                    Rating = buildInteraction.Rating
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildInteraction",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildInteraction.got", new
            {
                buildInteractionId = id,
                gotBy = currentUserId
            });

            //Return the buildInteraction
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting BuildInteractions with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BuildInteractionResponseDto>>> GetBuildInteractions([FromBody] GetBuildInteractionDto dto)
        {
            //Get buildInteraction id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.BuildInteractions.Include(i => i.Build).AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(i => dto.UserId.Contains(i.UserId));
            }
            if (dto.BuildId != null)
            {
                query = query.Where(i => dto.BuildId.Contains(i.BuildId));
            }
            if (dto.IsWishlisted != null)
            {
                query = query.Where(i => dto.IsWishlisted == i.IsWishlisted);
            }
            if (dto.IsLiked != null)
            {
                query = query.Where(i => dto.IsLiked == i.IsLiked);
            }
            if (dto.RatingStart != null)
            {
                query = query.Where(i => i.Rating >= dto.RatingStart);
            }
            if (dto.RatingEnd != null)
            {
                query = query.Where(i => i.Rating <= dto.RatingEnd);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(i => i.Build).Include(i => i.User).Search(dto.Query, i => i.Build!.Name, i => i.User!.DisplayName, i => i.Rating, i => i.UserNote!);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get buildInteractions with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<BuildInteraction> buildInteractions = await query.Where(i => currentUserId == i.UserId || isPrivileged || (i.Build != null && currentUserId == i.Build.UserId) || (i.Build != null && i.Build.Status != BuildStatus.DRAFT && i.Build.Status != BuildStatus.GENERATED)).ToListAsync();

            //Declare response variable
            List<BuildInteractionResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple BuildInteractions";

                //Create a buildInteraction response list
                responses = [.. buildInteractions.Select(buildInteraction =>
                {
                    //Return a follow response
                    return new BuildInteractionResponseDto
                    {
                        Id = buildInteraction.Id,
                        BuildId = buildInteraction.BuildId,
                        UserId = buildInteraction.UserId,
                        IsLiked = buildInteraction.IsLiked,
                        IsWishlisted = buildInteraction.IsWishlisted,
                        Rating = buildInteraction.Rating,
                        UserNote = buildInteraction.UserNote
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple BuildInteractions";

                //Create a buildInteraction response list
                responses = [.. buildInteractions.Select(buildInteraction => new BuildInteractionResponseDto
                {
                    Id = buildInteraction.Id,
                    BuildId = buildInteraction.BuildId,
                    UserId = buildInteraction.UserId,
                    IsLiked = buildInteraction.IsLiked,
                    IsWishlisted = buildInteraction.IsWishlisted,
                    Rating = buildInteraction.Rating,
                    UserNote = buildInteraction.UserNote,
                    DatabaseEntryAt = buildInteraction.DatabaseEntryAt,
                    LastEditedAt = buildInteraction.LastEditedAt,
                    Note = buildInteraction.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildInteraction",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildInteraction.gotBuildInteractions", new
            {
                buildInteractionIds = buildInteractions.Select(i => i.Id),
                gotBy = currentUserId
            });

            //Return the buildInteractions
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected BuildInteraction for staff.
        /// Used to remove marking that a user interacted with a build.
        /// Users can remove marking for their own interactions, while admins can remove them for all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteBuildInteraction(Guid id)
        {
            //Get buildInteraction id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildInteraction to delete
            var buildInteraction = await _db.BuildInteractions.Include(i => i.Build).FirstOrDefaultAsync(i => i.Id == id);
            if (buildInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "BuildInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildInteraction"
                );

                //Return not found response
                return NotFound(new { buildInteraction = "BuildInteraction not found!" });
            }

            //Check if current user is deleting their own buildInteraction or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildInteraction.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Delete the buildInteraction
            _db.BuildInteractions.Remove(buildInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "BuildInteraction",
                ip,
                buildInteraction.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildInteraction.deleted", new
            {
                buildInteractionId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildInteraction = "BuildInteraction deleted successfully!" });
        }
    }
}
