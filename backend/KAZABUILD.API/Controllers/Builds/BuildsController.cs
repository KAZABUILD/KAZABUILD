using KAZABUILD.Application.DTOs.Builds.Build;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic;
using System.Linq;
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

                if (dto.Status == BuildStatus.PUBLISHED)
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

            //Get the build to return
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == id);
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

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            BuildResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isSelf = currentUserId == build.UserId;
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

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
                    PublishedAt = build.PublishedAt
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
                    Note = build.Note
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

            //Declare the query
            var query = _db.Builds.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(b => dto.UserId.Contains(b.UserId));
            }
            if (dto.Name != null)
            {
                query = query.Where(b => dto.Name.Contains(b.Name));
            }
            if (dto.Status != null)
            {
                query = query.Where(b => dto.Status.Contains(b.Status));
            }
            if (dto.Tag != null)
            {
                query = query.Include(b => b.BuildTags).ThenInclude(t => t.Tag).Where(b => b.BuildTags.Any(t => dto.Tag.Contains(t.Tag!.Name)));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(b => b.User).Search(dto.Query, b => b.Name, b => b.Status, b => b.Description, b => b.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get builds with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<Build> builds = await query.Where(b => b.UserId == currentUserId || isPrivileged || (b.Status != BuildStatus.DRAFT && b.Status != BuildStatus.GENERATED)).ToListAsync();

            //Declare response variable
            List<BuildResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Builds";

                //Create a build response list
                responses = [.. builds.Select(build =>
                {
                    //Return a follow response
                    return new BuildResponseDto
                    {
                        Id = build.Id,
                        UserId = build.UserId,
                        Name = build.Name,
                        Description = build.Description,
                        Status = build.Status,
                        PublishedAt = build.PublishedAt
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Builds";

                //Create a build response list
                responses = [.. builds.Select(build => new BuildResponseDto
                {
                    Id = build.Id,
                    UserId = build.UserId,
                    Name = build.Name,
                    Description = build.Description,
                    Status = build.Status,
                    PublishedAt = build.PublishedAt,
                    DatabaseEntryAt = build.DatabaseEntryAt,
                    LastEditedAt = build.LastEditedAt,
                    Note = build.Note
                })];

            }

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
            var build = await _db.Builds
                .AsSplitQuery()
                .Include(b => b.Images)
                .Include(b => b.Comments)
                    .ThenInclude(c => c.ChildComments)
                .Include(b => b.Comments)
                    .ThenInclude(c => c.Images)
                .Include(b => b.Components)
                .Include(b => b.Interactions)
                .FirstOrDefaultAsync(b => b.Id == id);
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
                foreach (var comment in build.Comments)
                {
                    //Remove all related images
                    if (comment.Images.Count != 0)
                    {
                        foreach (var image in comment.Images)
                        {
                            //Remove the file from the file system
                            if (System.IO.File.Exists(image.Location))
                                System.IO.File.Delete(image.Location);
                        }

                        //Delete all related images
                        _db.Images.RemoveRange(comment.Images);
                    }

                    //Set the ParentCommentId field to null for all children
                    foreach (var child in comment.ChildComments)
                    {
                        child.ParentCommentId = null;
                    }

                    //Delete the userComment
                    _db.UserComments.Remove(comment);
                }
            }

            //Handle deleting build tags to avoid conflicts with cascade deletes
            //Get all tags
            var tags = await _db.BuildTags.Where(f => f.BuildId == build.Id).ToListAsync();

            //Remove all related tags
            if (tags.Count != 0)
            {
                _db.BuildTags.RemoveRange(tags);
            }

            //Set all related interactions foreign key field to null
            if (build.Interactions.Count != 0)
            {
                foreach(var interaction in  build.Interactions)
                {
                    interaction.BuildId = null;
                }
            }

            //Remove all components from build
            if (build.Components.Count != 0)
            {
                _db.BuildComponents.RemoveRange(build.Components);
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

        /// <summary>
        /// API Endpoint for creating a new Build.
        /// Used to create a draft of the build for users.
        /// Admins can create any status.
        /// </summary>
        /// <returns></returns>
        [HttpPost("generate")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> GenerateBuilds()
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the user exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == currentUserId);
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

            //Get user preference
            var answers = await _db.UserAnswers
                .OrderByDescending(a => a.DatabaseEntryAt)
                .Include(a => a.UserPreferenceAnswer)
                    .ThenInclude(pa => pa.UserPreference)
                .Where(u => u.UserId == currentUserId)
                .ToListAsync();

            //Question constants for readability
            const string HobbyQuestion = "What do you enjoy doing the most in your free time?";
            const string UsageQuestion = "What do you plan to use your PC for?";
            const string JobQuestion = "What do you do for work?";
            const string BudgetQuestion = "What's your budget?";
            const string PriorityQuestion = "What do you prioritize the most in your PC?";

            //Helper for removing unnecessary whitespace and normalizing questions
            static string NormalizeQuestion(string question) => question.Trim();

            //Dictionary grouping user answers by question
            var answersByQuestion = answers
                .Where(a => a.UserPreferenceAnswer?.UserPreference?.Question != null)
                .GroupBy
                (
                    a => NormalizeQuestion(a.UserPreferenceAnswer!.UserPreference!.Question),
                    StringComparer.OrdinalIgnoreCase
                )
                .ToDictionary
                (
                    g => g.Key,
                    g => g.Select(entry => entry.UserPreferenceAnswer!).ToList(),
                    StringComparer.OrdinalIgnoreCase
                );

            //Helper for checking if the user has answered a question
            bool HasAnswers(string question) =>
                answersByQuestion.ContainsKey(NormalizeQuestion(question));

            //Helper for getting answers for a question or an empty collection as a fallback
            IEnumerable<UserPreferenceAnswer> GetAnswersOrEmpty(string question) =>
                answersByQuestion.TryGetValue(NormalizeQuestion(question), out var result)
                    ? result
                    : Enumerable.Empty<UserPreferenceAnswer>();

            //Check if the required preferences have been set
            if (!HasAnswers(UsageQuestion) || !HasAnswers(JobQuestion) || !HasAnswers(BudgetQuestion))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Build",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - UserPreference For This User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User has not answered the questionnaire!" });
            }

            //Get the answers for each question
            var hobbyAnswers = GetAnswersOrEmpty(HobbyQuestion);
            var usageAnswers = GetAnswersOrEmpty(UsageQuestion);
            var jobAnswers = GetAnswersOrEmpty(JobQuestion);
            var priorityAnswers = GetAnswersOrEmpty(PriorityQuestion);
            var priceAnswers = GetAnswersOrEmpty(BudgetQuestion);

            //Declare a list for generated builds
            List<Build> generatedBuilds = [];

            //Declare initial bounds
            var bounds = new float[4]
            {
                2000.0f,
                0.0f,
                0.0f,
                200.0f
            };

            //Adjust the price bound accordingly
            if(priceAnswers.Select(a => a.Answer).Contains("$400–$600 (Entry Level)"))
            {
                bounds[0] = 400.0f;
                bounds[3] = 600.0f;
            }
            if (priceAnswers.Select(a => a.Answer).Contains("$600–$900 (Balanced Value)"))
            {
                if(bounds[0] > 600.0f)
                    bounds[0] = 600.0f;

                if (bounds[3] < 900.0f)
                    bounds[3] = 900.0f;
            }
            if (priceAnswers.Select(a => a.Answer).Contains("$900–$1200 (Upper Mid Range)"))
            {
                if (bounds[0] > 900.0f)
                    bounds[0] = 900.0f;

                if (bounds[3] < 1200.0f)
                    bounds[3] = 1200.0f;
            }
            if (priceAnswers.Select(a => a.Answer).Contains("$1200–$1800 (Performance Tier)"))
            {
                if (bounds[0] > 1200.0f)
                    bounds[0] = 1200.0f;

                if (bounds[3] < 1800.0f)
                    bounds[3] = 1800.0f;
            }
            if (priceAnswers.Select(a => a.Answer).Contains("$1800+ (Enthusiast / Future-proof)"))
            {
                if (bounds[0] > 1800.0f)
                    bounds[0] = 1800.0f;

                if (bounds[3] < 3000.0f)
                    bounds[3] = 3000.0f;
            }

            //Calculate middle bounds for the 3 price ranges
            bounds[1] = bounds[0] + ((bounds[3] - bounds[0]) * (1f/3f));
            bounds[2] = bounds[0] + ((bounds[3] - bounds[0]) * (2f/3f));

            //Convert the bounds to PLN
            bounds = [.. bounds.Select(b => b * 3.6f)];

            //Declare failure description for error logging
            var failureDescription = "";

            //Check for generation fail
            bool failed = false;

            //Generate each build
            for (int i = 0; i < 3; i++)
            {
                //Declare point values for calculating the price distribution ratios relative to each other
                float caseRatio = 0.4f;
                float caseFanRatio = 0.05f;
                float coolerRatio = 0.25f;
                float cpuRatio = 1.0f;
                float gpuRatio = 2.5f;
                float memoryRatio = 2.2f;
                float monitorRatio = 1.0f;
                float motherboardRatio = 1.0f;
                float powerSupplyRatio = 0.45f;
                float storageRatio = 0.7f;

                //Declare point values for calculating the price distribution relative to each other
                int coolerScore = 0;
                int cpuScore = 0;
                int gpuScore = 0;
                int memoryScore = 0;
                int monitorScore = 0;
                int storageScore = 0;

                //Declare a list of components for the build
                List<BaseComponent> components = [];

                //Create a build to add
                Build build = new()
                {
                    UserId = currentUserId,
                    Name = $"Generated build nr.{i+1} for {user.DisplayName}",
                    Description = "",
                    Status = BuildStatus.GENERATED,
                    PublishedAt = null,
                    DatabaseEntryAt = DateTime.UtcNow,
                    LastEditedAt = DateTime.UtcNow
                };

                //Add the build to the database
                _db.Builds.Add(build);
                await _db.SaveChangesAsync();

                //Add the build id to list for rabbitMQ publishing
                generatedBuilds.Add(build);

                //Adjust the scores base on the answers to the questions
                foreach (var answer in hobbyAnswers)
                {
                    var p = BuildGenerationHelper.HobbyAdjustments[answer.Answer];
                    gpuScore += p.gpu;
                    cpuScore += p.cpu;
                    memoryScore += p.memory;
                    storageScore += p.storage;
                    monitorScore += p.monitor;
                    coolerScore += p.cooler;
                }
                foreach (var answer in usageAnswers)
                {
                    var p = BuildGenerationHelper.UsageAdjustments[answer.Answer];
                    gpuScore += p.gpu;
                    cpuScore += p.cpu;
                    memoryScore += p.memory;
                    storageScore += p.storage;
                    monitorScore += p.monitor;
                    coolerScore += p.cooler;
                }
                foreach (var answer in jobAnswers)
                {
                    var p = BuildGenerationHelper.JobAdjustments[answer.Answer];
                    gpuScore += p.gpu;
                    cpuScore += p.cpu;
                    memoryScore += p.memory;
                    storageScore += p.storage;
                    monitorScore += p.monitor;
                    coolerScore += p.cooler;
                }
                foreach (var answer in priorityAnswers)
                {
                    var p = BuildGenerationHelper.PriorityAdjustments[answer.Answer];
                    gpuScore += p.gpu;
                    cpuScore += p.cpu;
                    memoryScore += p.memory;
                    storageScore += p.storage;
                    monitorScore += p.monitor;
                    coolerScore += p.cooler;
                }

                //Adjust the ratios based on the scores
                float averageScore = (float)(gpuScore + cpuScore + memoryScore + storageScore + monitorScore + coolerScore) / 6.0f;
                int totalScore = gpuScore + cpuScore + memoryScore + storageScore + monitorScore + coolerScore;
                gpuRatio *= 1 + (gpuScore - averageScore) / totalScore;
                cpuRatio *= 1 + (cpuScore - averageScore) / totalScore;
                memoryRatio *= 1 + (memoryScore - averageScore) / totalScore;
                storageRatio *= 1 + (storageScore - averageScore) / totalScore;
                monitorRatio *= 1 + (monitorScore - averageScore) / totalScore;
                coolerRatio *= 1 + (coolerScore - averageScore) / totalScore;
                motherboardRatio *= 1 + ((gpuRatio+cpuRatio)/2 - averageScore) / totalScore;

                //Additional criteria for filtering components
                decimal additionalPower = 0.0m;
                bool filterForExtraCores = false;
                bool filterFor4k = false;
                bool filterForQuietFans = false;
                bool filterForSSD = false;
                bool filterForRGB = false;

                //Make non-standard adjustments to ratios based on the answers
                if (priorityAnswers.Select(a => a.Answer).Contains("Reliability"))
                {
                    filterForSSD = true;
                }
                if (priorityAnswers.Select(a => a.Answer).Contains("Quiet Operation"))
                {
                    filterForQuietFans = true;
                }
                if (priorityAnswers.Select(a => a.Answer).Contains("Strong Graphics"))
                {
                    filterFor4k = true;
                }
                if (priorityAnswers.Select(a => a.Answer).Contains("Fast Multitasking"))
                {
                    filterForExtraCores = true;
                }
                if (priorityAnswers.Select(a => a.Answer).Contains("Looks"))
                {
                    caseRatio += 0.2f;
                    caseFanRatio += 0.1f;
                    filterForRGB = true;
                }
                if (usageAnswers.Select(a => a.Answer).Contains("AI Training"))
                {
                    additionalPower += 50.0m;
                    powerSupplyRatio += 0.1f;
                }

                //Get the components based on the scores and price bounds

                //Get the total ratio for all components
                float totalRatio = caseRatio + caseFanRatio + coolerRatio + cpuRatio + gpuRatio + memoryRatio + monitorRatio + motherboardRatio + powerSupplyRatio + storageRatio;

                //Get the price maximum and minimum for all the components
                var (caseMinPrice, caseMaxPrice) = BuildGenerationHelper.AllocateBudget(caseRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (caseFanMinPrice, caseFanMaxPrice) = BuildGenerationHelper.AllocateBudget(caseFanRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (coolerMinPrice, coolerMaxPrice) = BuildGenerationHelper.AllocateBudget(coolerRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (cpuMinPrice, cpuMaxPrice) = BuildGenerationHelper.AllocateBudget(cpuRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (gpuMinPrice, gpuMaxPrice) = BuildGenerationHelper.AllocateBudget(gpuRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (memoryMinPrice, memoryMaxPrice) = BuildGenerationHelper.AllocateBudget(memoryRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (monitorMinPrice, monitorMaxPrice) = BuildGenerationHelper.AllocateBudget(monitorRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (motherboardMinPrice, motherboardMaxPrice) = BuildGenerationHelper.AllocateBudget(motherboardRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (powerSupplyMinPrice, powerSupplyMaxPrice) = BuildGenerationHelper.AllocateBudget(powerSupplyRatio, totalRatio, bounds[i], bounds[i + 1]);
                var (storageMinPrice, storageMaxPrice) = BuildGenerationHelper.AllocateBudget(storageRatio, totalRatio, bounds[i], bounds[i + 1]);

                //Get all components that fit the criteria
                try
                {
                    //Get the CPU component
                    var cpuBaseQuery = _db.Components
                        .OfType<CPUComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.CPU);

                    var cpuComponent = await BuildGenerationHelper.FindComponentAsync(
                        cpuBaseQuery,
                        cpuMinPrice,
                        cpuMaxPrice,
                        q => q.OrderByIf(filterForExtraCores, c => c.CoreTotal)
                    );

                    if (cpuComponent == null)
                    {
                        failed = true;
                        failureDescription = $"cpu failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(cpuComponent);

                    //Get the motherboard component
                    var motherboardBaseQuery = _db.Components
                        .OfType<MotherboardComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.MOTHERBOARD)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == cpuComponent.Id));

                    var motherboardComponent = await BuildGenerationHelper.FindComponentAsync(
                        motherboardBaseQuery,
                        motherboardMinPrice,
                        motherboardMaxPrice,
                        q => q.OrderByIf(filterForRGB, c => (c.ARGB5vHeaderAmount > 0 || c.RGB12vHeaderAmount > 0) ? 0 : 1)
                    );

                    if (motherboardComponent == null)
                    {
                        failed = true;
                        failureDescription = $"motherboard failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(motherboardComponent);

                    //Get the cooler component
                    var coolerBaseQuery = _db.Components
                        .OfType<CoolerComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.COOLER)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == cpuComponent.Id) &&
                            c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id));

                    var coolerComponent = await BuildGenerationHelper.FindComponentAsync(
                        coolerBaseQuery,
                        coolerMinPrice,
                        coolerMaxPrice,
                        q => q.OrderByIf(filterForQuietFans, c => c.MinNoiseLevel)
                    );

                    if (coolerComponent == null)
                    {
                        failed = true;
                        failureDescription = $"cooler failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(coolerComponent);

                    //Get the memory component
                    var memoryBaseQuery = _db.Components
                        .OfType<MemoryComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.MEMORY)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id));

                    var memoryComponent = await BuildGenerationHelper.FindComponentAsync(
                        memoryBaseQuery,
                        memoryMinPrice,
                        memoryMaxPrice,
                        null
                    );

                    if (memoryComponent == null)
                    {
                        failed = true;
                        failureDescription = $"memory failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(memoryComponent);

                    //Get the storage component
                    var storageBaseQuery = _db.Components
                        .OfType<StorageComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.STORAGE)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id));

                    var storageComponent = await BuildGenerationHelper.FindComponentAsync(
                        storageBaseQuery,
                        storageMinPrice,
                        storageMaxPrice,
                        q => q.OrderByIf(filterForSSD, c => c.DriveType == "SSD" ? 0 : 1)
                    );

                    if (storageComponent == null)
                    {
                        failed = true;
                        failureDescription = $"storage failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(storageComponent);

                    //Get the GPU component
                    var gpuBaseQuery = _db.Components
                        .OfType<GPUComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.GPU)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id));

                    var gpuComponent = await BuildGenerationHelper.FindComponentAsync(
                        gpuBaseQuery,
                        gpuMinPrice,
                        gpuMaxPrice,
                        null
                    );

                    if (gpuComponent == null)
                    {
                        failed = true;
                        failureDescription = $"gpu failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(gpuComponent);

                    //Get the power supply component adjusting for the power usage in other components
                    var powerSupplyBaseQuery = _db.Components
                        .OfType<PowerSupplyComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.POWER_SUPPLY)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id))
                        .Where(c => c.PowerOutput > gpuComponent.ThermalDesignPower + cpuComponent.ThermalDesignPower + 100.0m + additionalPower); //Adjust for GPU, CPU + 100 extra + if any extra needed

                    var powerSupplyComponent = await BuildGenerationHelper.FindComponentAsync(
                        powerSupplyBaseQuery,
                        powerSupplyMinPrice,
                        powerSupplyMaxPrice,
                        null
                    );

                    if (powerSupplyComponent == null)
                    {
                        failed = true;
                        failureDescription = $"powerSupply failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(powerSupplyComponent);

                    //Get the case component
                    var caseBaseQuery = _db.Components
                        .OfType<CaseComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.CASE)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == gpuComponent.Id) &&

                        c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == coolerComponent.Id) &&
                        c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == motherboardComponent.Id));

                    var caseComponent = await BuildGenerationHelper.FindComponentAsync(
                        caseBaseQuery,
                        caseMinPrice,
                        caseMaxPrice,
                        null
                    );

                    if (caseComponent == null)
                    {
                        failed = true;
                        failureDescription = $"case failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(caseComponent);

                    //Get the case fan component
                    var caseFanBaseQuery = _db.Components
                        .OfType<CaseFanComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.CASE_FAN)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == caseComponent.Id));

                    var caseFanComponent = await BuildGenerationHelper.FindComponentAsync(
                        caseFanBaseQuery,
                        caseFanMinPrice,
                        caseFanMaxPrice,
                        q => q.OrderByIf(filterForQuietFans, c => c.MinNoiseLevel)
                    );

                    if (caseFanComponent == null)
                    {
                        failed = true;
                        failureDescription = $"caseFan failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(caseFanComponent);

                    //Get the monitor component
                    var monitorBaseQuery = _db.Components
                        .OfType<MonitorComponent>()
                        .Include(c => c.Prices.OrderByDescending(p => p.FetchedAt).Take(1))
                        .Where(c => c.Type == ComponentType.MONITOR)
                        .Where(c => c.CompatibleComponents.Any(cc => cc.CompatibleComponentId == gpuComponent.Id));

                    var monitorComponent = await BuildGenerationHelper.FindComponentAsync(
                        monitorBaseQuery,
                        monitorMinPrice,
                        monitorMaxPrice,
                        q => q.OrderByIf(filterFor4k, c => c.VerticalResolution >= 2160 ? 0 : 1)
                    );

                    if (monitorComponent == null)
                    {
                        failed = true;
                        failureDescription = $"monitor failed to generate in batch {i + 1}";
                        break;
                    }
                    components.Add(monitorComponent);
                }
                catch (Exception ex)
                {
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "Build",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.ERROR,
                        $"CPU Query Exception: {ex.Message} - {ex.InnerException?.Message}"
                    );
                    throw; // Re-throw to trigger proper error response
                }

                //Add all the components to the build
                foreach (BaseComponent component in components)
                {
                    BuildComponent buildComponent = new()
                    {
                        BuildId = build.Id,
                        ComponentId = component.Id,
                        Quantity = 1
                    };

                    _db.BuildComponents.Add(buildComponent);
                }

                //Add a description to the build
                var price = components.Select(c => c.Prices.OrderByDescending(p => p.FetchedAt).Select(p => p.Price).FirstOrDefault()).Sum();
                build.Description = $"A Build generated just for you for the lowest possible price of {price}. Remember to verify the prices on your own as they can differ from vendor to vendor!";
            }

            //Check if the components aren't null
            if (failed)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Build",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"Operation Failed - No Components Found That Fit The Selected Quiz Answers - {failureDescription}"
                );

                //Remove the generated builds from the database
                _db.Builds.RemoveRange(generatedBuilds);

                //Save changes to the database
                await _db.SaveChangesAsync();

                //Return proper error response
                return BadRequest(new { message = "No components found that fit the criteria!" });
            }

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the generation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Build",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Build Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("build.generated", new
            {
                buildIds = generatedBuilds.Select(b => b.Id),
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { build = "Builds generated successfully!" });
        }
    }
}
