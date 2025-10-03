using KAZABUILD.Application.DTOs.Users.ForumPost;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    //Controller for Forum Post related endpoints
    [ApiController]
    [Route("[controller]")]
    public class ForumPostsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        //API Endpoint for creating a new ForumPost
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddForumPost([FromBody] CreateForumPostDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Creator exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.CreatorId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ForumPost",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Creator not found!" });
            }

            //Check if current user has staff permissions or if they are creating a forum post for themselves
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.CreatorId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ForumPost",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a forumPost to add
            ForumPost forumPost = new()
            {
                CreatorId = dto.CreatorId,
                Content = dto.Content,
                Title = dto.Title,
                Topic = dto.Topic,
                PostedAt = dto.PostedAt,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the forumPost to the database
            _db.ForumPosts.Add(forumPost);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ForumPost",
                ip,
                forumPost.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Forum Post Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("forumPost.created", new
            {
                forumPostId = forumPost.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "New Forum Entry Posted successfully!", id = forumPost.Id });
        }

        //API endpoint for updating the selected ForumPost
        //User can modify only their own messages,
        //while staff can modify all 
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateForumPost(Guid id, [FromBody] UpdateForumPostDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the forumPost to edit
            var forumPost = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the forumPost exists
            if (forumPost == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ForumPost",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ForumPost"
                );

                //Return not found response
                return NotFound(new { message = "Forum Post not found!" });
            }

            //Check if current user has staff permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == forumPost.CreatorId;


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

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.Content))
            {
                changedFields.Add("Content: " + forumPost.Content);

                forumPost.Content = dto.Content;
            }
            if (!string.IsNullOrWhiteSpace(dto.Title))
            {
                changedFields.Add("Title: " + forumPost.Title);

                forumPost.Title = dto.Title;
            }
            if(isPrivileged)
            {
                if (!string.IsNullOrWhiteSpace(dto.Topic))
                {
                    changedFields.Add("Topic: " + forumPost.Topic);

                    forumPost.Topic = dto.Topic;
                }
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + forumPost.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        forumPost.Note = null;
                    else
                        forumPost.Note = dto.Note;
                }
            }

            //Update edit timestamp
            forumPost.LastEditedAt = DateTime.UtcNow;

            //Update the forumPost
            _db.ForumPosts.Update(forumPost);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ForumPost",
                ip,
                forumPost.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("forumPost.updated", new
            {
                forumPostId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Forum Post updated successfully!" });
        }

        //API endpoint for getting the ForumPost specified by id,
        //different level of information returned based on privileges
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ForumPostResponseDto>> GetForumPost(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the forumPost to return
            var forumPost = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == id);
            if (forumPost == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ForumPost",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ForumPost"
                );

                //Return not found response
                return NotFound(new { message = "Forum Post not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ForumPostResponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == forumPost.CreatorId;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create forumPost response
                response = new ForumPostResponseDto
                {
                    Id = forumPost.Id,
                    CreatorId = forumPost.CreatorId,
                    Content = forumPost.Content,
                    Title = forumPost.Title,
                    Topic = forumPost.Topic,
                    PostedAt = forumPost.PostedAt
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create forumPost response
                response = new ForumPostResponseDto
                {
                    Id = forumPost.Id,
                    CreatorId = forumPost.CreatorId,
                    Content = forumPost.Content,
                    Title = forumPost.Title,
                    Topic = forumPost.Topic,
                    PostedAt = forumPost.PostedAt,
                    DatabaseEntryAt = forumPost.DatabaseEntryAt,
                    LastEditedAt = forumPost.LastEditedAt,
                    Note = forumPost.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ForumPost",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("forumPost.got", new
            {
                forumPostId = id,
                gotBy = currentUserId
            });

            //Return the forumPost
            return Ok(response);
        }

        //API endpoint for getting ForumPosts with pagination and search,
        //different level of information returned based on privileges
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ForumPostResponseDto>>> GetForumPosts([FromBody] GetForumPostDto dto)
        {
            //Get forumPost id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ForumPosts.AsNoTracking();

            //Filter by the variables if included
            if (dto.Topic != null)
            {
                query = query.Where(p => dto.Topic.Contains(p.Topic));
            }
            if (dto.CreatorId != null)
            {
                query = query.Where(p => dto.CreatorId.Contains(p.CreatorId));
            }
            if (dto.PostedAtStart != null)
            {
                query = query.Where(p => p.PostedAt >= dto.PostedAtStart);
            }
            if (dto.PostedAtEnd != null)
            {
                query = query.Where(p => p.PostedAt <= dto.PostedAtEnd);
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(p => p.Creator).Search(dto.Query, p => p.PostedAt, p => p.Title, p => p.Content, p => p.Topic, p => p.Creator!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get forumPosts with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ForumPost> forumPosts = await query.ToListAsync();

            //Declare response variable
            List<ForumPostResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ForumPosts";

                //Create a forumPost response list
                responses = [.. forumPosts.Select(forumPost =>
                {
                    //Return a follow response
                    return new ForumPostResponseDto
                    {
                        Id = forumPost.Id,
                        CreatorId = forumPost.CreatorId,
                        Content = forumPost.Content,
                        Title = forumPost.Title,
                        Topic = forumPost.Topic,
                        PostedAt = forumPost.PostedAt
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ForumPosts";

                //Create a forumPost response list
                responses = [.. forumPosts.Select(forumPost => new ForumPostResponseDto
                {
                    Id = forumPost.Id,
                    CreatorId = forumPost.CreatorId,
                    Content = forumPost.Content,
                    Title = forumPost.Title,
                    Topic = forumPost.Topic,
                    PostedAt = forumPost.PostedAt,
                    DatabaseEntryAt = forumPost.DatabaseEntryAt,
                    LastEditedAt = forumPost.LastEditedAt,
                    Note = forumPost.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ForumPost",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("forumPost.gotForumPosts", new
            {
                forumPostIds = forumPosts.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the forumPosts
            return Ok(responses);
        }

        //API endpoint for deleting the selected ForumPost for administration
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteForumPost(Guid id)
        {
            //Get forumPost id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the forumPost to delete
            var forumPost = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == id);
            if (forumPost == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ForumPost",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ForumPost"
                );

                //Return not found response
                return NotFound(new { message = "ForumPost not found!" });
            }

            //Check if current user has staff permissions or if they are deleting their own post
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == forumPost.CreatorId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserFollow",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Delete the forumPost
            _db.ForumPosts.Remove(forumPost);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ForumPost",
                ip,
                forumPost.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("forumPost.deleted", new
            {
                forumPostId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "ForumPost deleted successfully!" });
        }
    }
}
