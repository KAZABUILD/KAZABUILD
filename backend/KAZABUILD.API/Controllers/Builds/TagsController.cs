using KAZABUILD.Application.DTOs.Builds.Tag;
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
    /// Controller for Tag related endpoints.
    /// Managed by administration.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class TagsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new Tag for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddTag([FromBody] CreateTagDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Tag already exists
            var tagExists = await _db.Tags.FirstOrDefaultAsync(t => t.Name == dto.Name);
            if (tagExists == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Tag",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Tag Already Created"
                );

                //Return proper error response
                return Conflict(new { message = "Tag already exists!" });
            }

            //Create a tag to add
            Tag tag = new()
            {
                Name = dto.Name,
                Description = dto.Description,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the tag to the database
            _db.Tags.Add(tag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Tag",
                ip,
                tag.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Tag Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("tag.created", new
            {
                tagId = tag.Id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { tag = "Tag added successfully!", id = tag.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected Tag for Administration,
        /// the id is a string representing the hex code of the Tag.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateTag(Guid id, [FromBody] UpdateTagDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the tag to edit
            var tag = await _db.Tags.FirstOrDefaultAsync(t => t.Id == id);

            //Check if the tag exists
            if (tag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Tag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Tag"
                );

                //Return not found response
                return NotFound(new { tag = "Tag not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update fields
            if (!string.IsNullOrWhiteSpace(dto.Name))
            {
                changedFields.Add("Name: " + tag.Name);

                tag.Name = dto.Name;
            }
            if (!string.IsNullOrWhiteSpace(dto.Description))
            {
                changedFields.Add("Description: " + tag.Description);

                tag.Description = dto.Description;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + tag.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    tag.Note = null;
                else
                    tag.Note = dto.Note;
            }

            //Update edit timestamp
            tag.LastEditedAt = DateTime.UtcNow;

            //Update the tag
            _db.Tags.Update(tag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Tag",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("tag.updated", new
            {
                tagId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { tag = "Tag updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Tag specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<TagResponseDto>> GetTag(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the tag to return
            var tag = await _db.Tags.FirstOrDefaultAsync(t => t.Id == id);
            if (tag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Tag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Tag"
                );

                //Return not found response
                return NotFound(new { tag = "Tag not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            TagResponseDto response;

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create tag response
                response = new TagResponseDto
                {
                    Name = tag.Name,
                    Description = tag.Description
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create tag response
                response = new TagResponseDto
                {
                    Name = tag.Name,
                    Description = tag.Description,
                    DatabaseEntryAt = tag.DatabaseEntryAt,
                    LastEditedAt = tag.LastEditedAt,
                    Note = tag.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Tag",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("tag.got", new
            {
                tagId = id,
                gotBy = currentUserId
            });

            //Return the tag
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Tags with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<TagResponseDto>>> GetTags([FromBody] GetTagDto dto)
        {
            //Get tag id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Tags.AsNoTracking();

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, t => t.Name, t => t.Description);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get tags with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<Tag> tags = await query.ToListAsync();

            //Declare response variable
            List<TagResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Tags";

                //Create a tag response list
                responses = [.. tags.Select(tag =>
                {
                    //Return a follow response
                    return new TagResponseDto
                    {
                        Name = tag.Name,
                        Description = tag.Description
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Tags";

                //Create a tag response list
                responses = [.. tags.Select(tag => new TagResponseDto
                {
                    Name = tag.Name,
                    Description = tag.Description,
                    DatabaseEntryAt = tag.DatabaseEntryAt,
                    LastEditedAt = tag.LastEditedAt,
                    Note = tag.Note,
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Tag",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("tag.gotTags", new
            {
                tagIds = tags.Select(t => t.Id),
                gotdBy = currentUserId
            });

            //Return the tags
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Tag for administration.
        /// Removes all related BuiltTags as well.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteTag(Guid id)
        {
            //Get tag id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the tag to delete
            var tag = await _db.Tags.Include(t => t.BuildTags).FirstOrDefaultAsync(t => t.Id == id);
            if (tag == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Tag",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Tag"
                );

                //Return not found response
                return NotFound(new { tag = "Tag not found!" });
            }

            //Delete all associated BuildTags
            if (tag.Builds.Count != 0)
            {
                _db.BuildTags.RemoveRange(tag.BuildTags);
            }

            //Delete the tag
            _db.Tags.Remove(tag);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Tag",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("tag.deleted", new
            {
                tagId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { tag = "Tag deleted successfully!" });
        }
    }
}
