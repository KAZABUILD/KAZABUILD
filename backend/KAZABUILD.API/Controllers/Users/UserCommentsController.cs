using KAZABUILD.Application.DTOs.Users.UserComment;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    /// <summary>
    /// Controller for UserComment related endpoints.
    /// UserComments can be sent between all users, staff, system and bots.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserCommentsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for posting a new UserComment.
        /// User can post their own comments, while staff can post for all.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserComment([FromBody] CreateUserCommentDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the User exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserComment",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has admin permissions or if they are posting a comment for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserComment",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userComment to add
            UserComment userComment = new()
            {
                UserId = dto.UserId,
                Content = dto.Content,
                PostedAt = dto.PostedAt,
                ParentCommentId = dto.ParentCommentId,
                CommentTargetType = dto.CommentTargetType,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the target id depending on the CommentTargetType
            switch (userComment.CommentTargetType)
            {
                case CommentTargetType.BUILD:
                    //Set the target as build
                    userComment.BuildId = dto.TargetId;

                    //Check if the build exists
                    var build = await _db.Builds.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (build == null || build.Status == BuildStatus.DRAFT || build.Status == BuildStatus.GENERATED)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserComment",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Build Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Build not found!" });
                    }

                    break;
                case CommentTargetType.COMPONENT:
                    //Set the target as component
                    userComment.ComponentId = dto.TargetId;

                    //Check if the component exists
                    var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (component == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserComment",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Component Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Component not found!" });
                    }

                    break;
                case CommentTargetType.REVIEW:
                    //Set the target as review
                    userComment.ComponentReviewId = dto.TargetId;

                    //Check if the review exists
                    var review = await _db.ComponentReviews.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (review == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserComment",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Review Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Review not found!" });
                    }

                    break;
                case CommentTargetType.FORUM:
                    //Set the target as post
                    userComment.ForumPostId = dto.TargetId;

                    //Check if the post exists
                    var post = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (post == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserComment",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - ForumPost Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "ForumPost not found!" });
                    }

                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "UserComment",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper unauthorized response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Add the userComment to the database
            _db.UserComments.Add(userComment);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserComment",
                ip,
                userComment.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserComment Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userComment.created", new
            {
                userCommentId = userComment.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Comment posted successfully!", id = userComment.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserComment.
        /// User can modify only the contents, while staff can modify all.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUserComment(Guid id, [FromBody] UpdateUserCommentDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userComment to edit
            var userComment = await _db.UserComments.FirstOrDefaultAsync(c => c.Id == id);
            //Check if the userComment exists
            if (userComment == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserComment",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserComment"
                );

                //Return not found response
                return NotFound(new { message = "UserComment not found!" });
            }

            //Check if current user has admin permissions or if they are modifying a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userComment.UserId;

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
                changedFields.Add("Content: " + userComment.Content);

                userComment.Content = dto.Content;
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + userComment.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        userComment.Note = null;
                    else
                        userComment.Note = dto.Note;
                }
            }

            //Update edit timestamp
            userComment.LastEditedAt = DateTime.UtcNow;

            //Update the userComment
            _db.UserComments.Update(userComment);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserComment",
                ip,
                userComment.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userComment.updated", new
            {
                userCommentId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Comment updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserComment specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserCommentResponseDto>> GetUserComment(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userComment to return
            var userComment = await _db.UserComments.FirstOrDefaultAsync(c => c.Id == id);
            if (userComment == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserComment",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserComment"
                );

                //Return not found response
                return NotFound(new { message = "UserComment not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserCommentResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userComment response
                response = new UserCommentResponseDto
                {
                    Id = userComment.Id,
                    UserId = userComment.UserId,
                    Content = userComment.Content,
                    PostedAt = userComment.PostedAt,
                    ParentCommentId = userComment.ParentCommentId,
                    CommentTargetType = userComment.CommentTargetType
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userComment response
                response = new UserCommentResponseDto
                {
                    Id = userComment.Id,
                    UserId = userComment.UserId,
                    Content = userComment.Content,
                    PostedAt = userComment.PostedAt,
                    ParentCommentId = userComment.ParentCommentId,
                    CommentTargetType = userComment.CommentTargetType,
                    DatabaseEntryAt = userComment.DatabaseEntryAt,
                    LastEditedAt = userComment.LastEditedAt,
                    Note = userComment.Note,
                };
            }

            //Add the target id depending on the CommentTargetType
            switch (userComment.CommentTargetType)
            {
                case CommentTargetType.BUILD:
                    response.BuildId = userComment.BuildId;
                    break;
                case CommentTargetType.COMPONENT:
                    response.ComponentId = userComment.ComponentId;
                    break;
                case CommentTargetType.REVIEW:
                    response.ComponentReviewId = userComment.ComponentReviewId;
                    break;
                case CommentTargetType.FORUM:
                    response.ForumPostId = userComment.ForumPostId;
                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "UserComment",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper unauthorized response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserComment",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userComment.got", new
            {
                userCommentId = id,
                gotBy = currentUserId
            });

            //Return the userComment
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserComments with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserCommentResponseDto>>> GetUserComments([FromBody] GetUserCommentDto dto)
        {
            //Get userComment id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserComments.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(c => dto.UserId.Contains(c.UserId));
            }
            if (dto.PostedAtStart != null)
            {
                query = query.Where(c => c.PostedAt >= dto.PostedAtStart);
            }
            if (dto.PostedAtEnd != null)
            {
                query = query.Where(c => c.PostedAt <= dto.PostedAtEnd);
            }
            if (dto.ParentCommentId != null)
            {
                query = query.Where(c => c.ParentCommentId != null && dto.ParentCommentId.Contains((Guid)c.ParentCommentId));
            }
            if (dto.CommentTargetType != null)
            {
                query = query.Where(c => dto.CommentTargetType.Contains(c.CommentTargetType));
            }
            if (dto.ForumPostId != null)
            {
                query = query.Where(c => c.ForumPostId != null && dto.ForumPostId.Contains((Guid)c.ForumPostId));
            }
            if (dto.BuildId != null)
            {
                query = query.Where(c => c.BuildId != null && dto.BuildId.Contains((Guid)c.BuildId));
            }
            if (dto.ComponentId != null)
            {
                query = query.Where(c => c.ComponentId != null && dto.ComponentId.Contains((Guid)c.ComponentId));
            }
            if (dto.ComponentReviewId != null)
            {
                query = query.Where(c => c.ComponentReviewId != null && dto.ComponentReviewId.Contains((Guid)c.ComponentReviewId));
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(c => c.User).Search(dto.Query, c => c.PostedAt, c => c.Content, c => c.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userComments with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserComment> userComments = await query.ToListAsync();

            //Declare response variable
            List<UserCommentResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserComments";

                //Create a userComment response list
                responses = [.. userComments.Select(userComment =>
                {
                    //Return a follow response
                    return new UserCommentResponseDto
                    {
                        Id = userComment.Id,
                        UserId = userComment.UserId,
                        Content = userComment.Content,
                        PostedAt = userComment.PostedAt,
                        ParentCommentId = userComment.ParentCommentId,
                        CommentTargetType = userComment.CommentTargetType,
                        ComponentId = userComment.CommentTargetType == CommentTargetType.COMPONENT ? userComment.ComponentId : null,
                        ComponentReviewId = userComment.CommentTargetType == CommentTargetType.REVIEW ? userComment.ComponentReviewId : null,
                        BuildId = userComment.CommentTargetType == CommentTargetType.BUILD ? userComment.BuildId : null,
                        ForumPostId = userComment.CommentTargetType == CommentTargetType.FORUM ? userComment.ForumPostId : null
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserComments";

                //Create a userComment response list
                responses = [.. userComments.Select(userComment => new UserCommentResponseDto
                {
                    Id = userComment.Id,
                    UserId = userComment.UserId,
                    Content = userComment.Content,
                    PostedAt = userComment.PostedAt,
                    ParentCommentId = userComment.ParentCommentId,
                    CommentTargetType = userComment.CommentTargetType,
                    ComponentId = userComment.CommentTargetType == CommentTargetType.COMPONENT ? userComment.ComponentId : null,
                    ComponentReviewId = userComment.CommentTargetType == CommentTargetType.REVIEW ? userComment.ComponentReviewId : null,
                    BuildId = userComment.CommentTargetType == CommentTargetType.BUILD ? userComment.BuildId : null,
                    ForumPostId = userComment.CommentTargetType == CommentTargetType.FORUM ? userComment.ForumPostId : null,
                    DatabaseEntryAt = userComment.DatabaseEntryAt,
                    LastEditedAt = userComment.LastEditedAt,
                    Note = userComment.Note
                })];
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserComment",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userComment.gotUserComments", new
            {
                userCommentIds = userComments.Select(c => c.Id),
                gotBy = currentUserId
            });

            //Return the userComments
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserComment.
        /// Users can delete userComments they sent and staff can delete all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserComment(Guid id)
        {
            //Get userComment id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userComment to delete
            var userComment = await _db.UserComments.FirstOrDefaultAsync(c => c.Id == id);
            if (userComment == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserComment",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserComment"
                );

                //Return not found response
                return NotFound(new { message = "UserComment not found!" });
            }

            //Check if current user has admin permissions or if they are deleting their own comment
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userComment.UserId;

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

            //Delete the userComment
            _db.UserComments.Remove(userComment);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserComment",
                ip,
                userComment.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userComment.deleted", new
            {
                userCommentId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserComment deleted successfully!" });
        }
    }
}
