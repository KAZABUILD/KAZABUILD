using KAZABUILD.Application.DTOs.Builds.BuildTag;
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
    /// Controller for BuildTag related endpoints.
    /// Used to connect SubComponents with a Component which they are a part of.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class BuildTagsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for adding a new Tag to a Build.
        /// Users can tag their own builds, while admins can tag them all.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddBuildTag([FromBody] CreateBuildTagDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Build exists
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == dto.BuildId);
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildTag",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Build Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Build not found!" });
            }

            //Check if the Tag exists
            var tag = await _db.Tags.FirstOrDefaultAsync(t => t.Id == dto.TagId);
            if (tag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildTag",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Tag Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Tag not found!" });
            }

            //Check if current user has admin permissions or if they are tagging their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var ownBuild = currentUserId == build.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !(ownBuild && build.Status != BuildStatus.DRAFT && build.Status != BuildStatus.GENERATED))
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

            //Create a buildTag to add
            BuildTag buildTag = new()
            {
                BuildId = dto.BuildId,
                TagId = dto.TagId,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the buildTag to the database
            _db.BuildTags.Add(buildTag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "BuildTag",
                ip,
                buildTag.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New BuildTag Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildTag.created", new
            {
                buildTagId = buildTag.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { buildTag = "BuildTag created successfully!", id = buildTag.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected BuildTag's administration note.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateBuildTag(Guid id, [FromBody] UpdateBuildTagDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildTag to edit
            var buildTag = await _db.BuildTags.Include(t => t.Build).FirstOrDefaultAsync(t => t.Id == id);

            //Check if the buildTag exists
            if (buildTag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "BuildTag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildTag"
                );

                //Return not found response
                return NotFound(new { buildTag = "BuildTag not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + buildTag.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    buildTag.Note = null;
                else
                    buildTag.Note = dto.Note;
            }

            //Update edit timestamp
            buildTag.LastEditedAt = DateTime.UtcNow;

            //Update the buildTag
            _db.BuildTags.Update(buildTag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description for whether the note was updated
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "BuildTag",
                ip,
                buildTag.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildTag.updated", new
            {
                buildTagId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildTag = "BuildTag updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the BuildTag specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BuildTagResponseDto>> GetBuildTag(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildTag to return
            var buildTag = await _db.BuildTags.FirstOrDefaultAsync(t => t.Id == id);
            if (buildTag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildTag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildTag"
                );

                //Return not found response
                return NotFound(new { buildTag = "BuildTag not found!" });
            }

            //Check if current user has admin permissions or if they are tagging to their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var ownBuild = currentUserId == buildTag.Build!.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !ownBuild && (buildTag.Build!.Status == BuildStatus.DRAFT || buildTag.Build!.Status == BuildStatus.GENERATED))
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

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            BuildTagResponseDto response;

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create buildTag response
                response = new BuildTagResponseDto
                {
                    Id = buildTag.Id,
                    TagId = buildTag.TagId,
                    BuildId = buildTag.BuildId
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create buildTag response
                response = new BuildTagResponseDto
                {
                    Id = buildTag.Id,
                    TagId = buildTag.TagId,
                    BuildId = buildTag.BuildId,
                    DatabaseEntryAt = buildTag.DatabaseEntryAt,
                    LastEditedAt = buildTag.LastEditedAt,
                    Note = buildTag.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildTag",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildTag.got", new
            {
                buildTagId = id,
                gotBy = currentUserId
            });

            //Return the buildTag
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting BuildTags with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BuildTagResponseDto>>> GetBuildTags([FromBody] GetBuildTagDto dto)
        {
            //Get buildTag id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.BuildTags.AsNoTracking();

            //Filter by the variables if included
            if (dto.TagId != null)
            {
                query = query.Where(t => dto.TagId.Contains(t.TagId));
            }
            if (dto.BuildId != null)
            {
                query = query.Where(t => dto.BuildId.Contains(t.BuildId));
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(p => p.Build).Include(p => p.Tag).Search(dto.Query, t => t.Tag!.Name, t => t.Build!.Name);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get buildTags with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<BuildTag> buildTags = await query.Where(t => currentUserId == t.Build!.UserId || isPrivileged || (t.Build!.Status != BuildStatus.DRAFT && t.Build!.Status != BuildStatus.GENERATED)).ToListAsync();

            //Declare response variable
            List<BuildTagResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple BuildTags";

                //Create a buildTag response list
                responses = [.. buildTags.Select(buildTag =>
                {
                    //Return a follow response
                    return new BuildTagResponseDto
                    {
                        Id = buildTag.Id,
                        TagId = buildTag.TagId,
                        BuildId = buildTag.BuildId
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple BuildTags";

                //Create a buildTag response list
                responses = [.. buildTags.Select(buildTag => new BuildTagResponseDto
                {
                    Id = buildTag.Id,
                    TagId = buildTag.TagId,
                    BuildId = buildTag.BuildId,
                    DatabaseEntryAt = buildTag.DatabaseEntryAt,
                    LastEditedAt = buildTag.LastEditedAt,
                    Note = buildTag.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildTag",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildTag.gotBuildTags", new
            {
                buildTagIds = buildTags.Select(t => t.Id),
                gotBy = currentUserId
            });

            //Return the buildTags
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for untagging the build through a selected BuildTag.
        /// Users can untag their own builds, while admins can untag them all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteBuildTag(Guid id)
        {
            //Get buildTag id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildTag to delete
            var buildTag = await _db.BuildTags.FirstOrDefaultAsync(t => t.Id == id);
            if (buildTag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "BuildTag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildTag"
                );

                //Return not found response
                return NotFound(new { buildTag = "BuildTag not found!" });
            }

            //Check if current user has admin permissions or if they are untagging their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var ownBuild = currentUserId == buildTag.Build!.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !(ownBuild && buildTag.Build!.Status != BuildStatus.DRAFT && buildTag.Build!.Status != BuildStatus.GENERATED))
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

            //Delete the buildTag
            _db.BuildTags.Remove(buildTag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "BuildTag",
                ip,
                buildTag.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildTag.deleted", new
            {
                buildTagId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildTag = "BuildTag deleted successfully!" });
        }
    }
}
