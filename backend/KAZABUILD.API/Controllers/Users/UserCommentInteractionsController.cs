using KAZABUILD.Application.DTOs.Builds.BuildInteraction;
using KAZABUILD.Application.DTOs.Users.UserCommentInteraction;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
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
    /// Controller for UserCommentInteraction related endpoints.
    /// Allows users to interact with public userComments.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserCommentInteractionsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new UserCommentInteraction.
        /// Used to mark that a user interacted with a userComment.
        /// Users can mark their own interactions, while admins can mark them for all.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserCommentInteraction([FromBody] CreateUserCommentInteractionDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the userComment exists
            var userComment = await _db.UserComments.Include(c => c.Build).FirstOrDefaultAsync(c => c.Id == dto.UserCommentId);
            if (userComment == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - UserComment Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Comment not found!" });
            }

            //Check if the user exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if the user hadn't already interacted with this component
            var interaction = await _db.UserCommentInteractions.FirstOrDefaultAsync(i => i.UserId == dto.UserId && i.UserCommentId == dto.UserCommentId);
            if (interaction != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - UserComment Already Interacted With"
                );

                //Return proper error response
                return BadRequest(new { message = "Interaction already exists!" });
            }

            //Check if the dislike and like aren't being set at the same time
            if (dto.IsDisliked && dto.IsLiked)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Interaction Incorrect"
                );

                //Return proper error response
                return BadRequest(new { message = "Interaction cannot be both positive and negative!" });
            }

            //Check if current user has admin permissions, is interacting as themselves or if they are adding an interaction to their own userComment
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;
            var ownUserComment = currentUserId == userComment.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the user isn't interacting with a comment on a private build
            if (!isPrivileged && !ownUserComment && (userComment.Build == null || userComment.Build.Status == BuildStatus.DRAFT || userComment.Build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid UserComment Status"
                );

                //Return proper error response
                return BadRequest(new { message = "UserComment is not public!" });
            }

            //Create a userCommentInteraction to add
            UserCommentInteraction userCommentInteraction = new()
            {
                UserCommentId = dto.UserCommentId,
                UserId = dto.UserId,
                IsLiked = dto.IsLiked,
                IsDisliked = dto.IsDisliked,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userCommentInteraction to the database
            _db.UserCommentInteractions.Add(userCommentInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserCommentInteraction",
                ip,
                userCommentInteraction.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserCommentInteraction Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.created", new
            {
                userCommentInteractionId = userCommentInteraction.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { userCommentInteraction = "UserCommentInteraction created successfully!", id = userCommentInteraction.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserCommentInteraction.
        /// Users can modify all fields.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUserCommentInteraction(Guid id, [FromBody] UpdateUserCommentInteractionDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userCommentInteraction to edit
            var userCommentInteraction = await _db.UserCommentInteractions.Include(c => c.UserComment).FirstOrDefaultAsync(i => i.Id == id);

            //Check if the userCommentInteraction exists
            if (userCommentInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserCommentInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserCommentInteraction"
                );

                //Return not found response
                return NotFound(new { userCommentInteraction = "UserCommentInteraction not found!" });
            }

            //Check if the userComment was deleted
            var userComment = await _db.UserComments.FirstOrDefaultAsync(b => b.Id == userCommentInteraction.UserCommentId);
            if (userComment == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    "Operation Failed - UserComment Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "UserComment not found!" });
            }

            //Check if current user is modifying their own userComment, is interacting as themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userCommentInteraction.UserId;
            var ownUserComment = currentUserId == userComment.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the user isn't interacting with a private build
            if (!isPrivileged && !ownUserComment && (userComment.Build == null || userComment.Build.Status == BuildStatus.DRAFT || userComment.Build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Comment left under a non-public build!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.IsLiked != null)
            {
                changedFields.Add("IsLiked: " + userCommentInteraction.IsLiked);

                userCommentInteraction.IsLiked = (bool)dto.IsLiked;

                //Set the IsDisliked field to false if IsLiked set to true
                if(dto.IsLiked == true)
                {
                    userCommentInteraction.IsDisliked = false;
                }
            }
            if (dto.IsDisliked != null)
            {
                changedFields.Add("IsDisliked: " + userCommentInteraction.IsDisliked);

                userCommentInteraction.IsDisliked = (bool)dto.IsDisliked;

                //Set the IsLiked field to false if IsDisliked set to true
                if (dto.IsDisliked == true)
                {
                    userCommentInteraction.IsLiked = false;
                }
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + userCommentInteraction.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        userCommentInteraction.Note = null;
                    else
                        userCommentInteraction.Note = dto.Note;
                }
            }

            //Update edit timestamp
            userCommentInteraction.LastEditedAt = DateTime.UtcNow;

            //Update the userCommentInteraction
            _db.UserCommentInteractions.Update(userCommentInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserCommentInteraction",
                ip,
                userCommentInteraction.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.updated", new
            {
                userCommentInteractionId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { userCommentInteraction = "UserCommentInteraction updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserCommentInteraction specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserCommentInteractionResponseDto>> GetUserCommentInteraction(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userCommentInteraction to return
            var userCommentInteraction = await _db.UserCommentInteractions.Include(i => i.UserComment).FirstOrDefaultAsync(i => i.Id == id);
            if (userCommentInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserCommentInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserCommentInteraction"
                );

                //Return not found response
                return NotFound(new { userCommentInteraction = "UserCommentInteraction not found!" });
            }

            //Check if the userComment was deleted
            var userComment = await _db.UserComments.Include(c => c.Build).FirstOrDefaultAsync(b => b.Id == userCommentInteraction.UserCommentId);

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserCommentInteractionResponseDto response;

            //Check if current user is getting their own userComment, is interacting as themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userCommentInteraction.UserId;
            var ownUserComment = userComment != null && currentUserId == userComment.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isPrivileged && !isSelf && !ownUserComment && (userComment == null || userComment.Build == null || userComment.Build.Status == BuildStatus.DRAFT || userComment.Build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserCommentComponent",
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

                //Create userCommentInteraction response
                response = new UserCommentInteractionResponseDto
                {
                    Id = userCommentInteraction.Id,
                    UserCommentId = userCommentInteraction.UserCommentId,
                    UserId = userCommentInteraction.UserId,
                    IsLiked = userCommentInteraction.IsLiked,
                    IsDisliked = userCommentInteraction.IsDisliked,
                    DatabaseEntryAt = userCommentInteraction.DatabaseEntryAt,
                    LastEditedAt = userCommentInteraction.LastEditedAt,
                    Note = userCommentInteraction.Note,
                };
            }
            else if (isSelf)
            {
                //Change log description
                logDescription = "Successful Operation - Private Access";

                //Create userCommentInteraction response
                response = new UserCommentInteractionResponseDto
                {
                    Id = userCommentInteraction.Id,
                    UserCommentId = userCommentInteraction.UserCommentId,
                    UserId = userCommentInteraction.UserId,
                    IsLiked = userCommentInteraction.IsLiked,
                    IsDisliked = userCommentInteraction.IsDisliked,
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Public Access";

                //Create userCommentInteraction response
                response = new UserCommentInteractionResponseDto
                {
                    Id = userCommentInteraction.Id,
                    UserCommentId = userCommentInteraction.UserCommentId,
                    IsLiked = userCommentInteraction.IsLiked,
                    IsDisliked = userCommentInteraction.IsDisliked,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserCommentInteraction",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.got", new
            {
                userCommentInteractionId = id,
                gotBy = currentUserId
            });

            //Return the userCommentInteraction
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserCommentInteractions with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserCommentInteractionResponseDto>>> GetUserCommentInteractions([FromBody] GetUserCommentInteractionDto dto)
        {
            //Get userCommentInteraction id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserCommentInteractions.Include(i => i.UserComment).AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(i => dto.UserId.Contains(i.UserId));
            }
            if (dto.UserCommentId != null)
            {
                query = query.Where(i => dto.UserCommentId.Contains(i.UserCommentId));
            }
            if (dto.IsLiked != null)
            {
                query = query.Where(i => dto.IsLiked == i.IsLiked);
            }
            if (dto.IsDisliked != null)
            {
                query = query.Where(i => dto.IsDisliked == i.IsDisliked);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(i => i.User).Search(dto.Query, i => i.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userCommentInteractions with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserCommentInteraction> userCommentInteractions = await query.Where(i => currentUserId == i.UserId || isPrivileged || (i.UserComment != null && currentUserId == i.UserComment.UserId) || (i.UserComment != null && i.UserComment.Build != null && i.UserComment.Build.Status != BuildStatus.DRAFT && i.UserComment.Build.Status != BuildStatus.GENERATED)).ToListAsync();

            //Declare response variable
            List<UserCommentInteractionResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserCommentInteractions";

                //Create a userCommentInteraction response list
                responses = [.. userCommentInteractions.Select(userCommentInteraction =>
                {
                    //Check the if is own interaction
                    if(currentUserId == userCommentInteraction.UserId)
                    {
                        //Return a CommentInteraction response
                        return new UserCommentInteractionResponseDto
                        {
                            Id = userCommentInteraction.Id,
                            UserCommentId = userCommentInteraction.UserCommentId,
                            UserId = userCommentInteraction.UserId,
                            IsLiked = userCommentInteraction.IsLiked,
                            IsDisliked = userCommentInteraction.IsDisliked
                        };
                    }
                    else
                    {
                        //Return a CommentInteraction response
                        return new UserCommentInteractionResponseDto
                        {
                            Id = userCommentInteraction.Id,
                            UserCommentId = userCommentInteraction.UserCommentId,
                            IsLiked = userCommentInteraction.IsLiked,
                            IsDisliked = userCommentInteraction.IsDisliked
                        };
                    }
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserCommentInteractions";

                //Create a userCommentInteraction response list
                responses = [.. userCommentInteractions.Select(userCommentInteraction => new UserCommentInteractionResponseDto
                {
                    Id = userCommentInteraction.Id,
                    UserCommentId = userCommentInteraction.UserCommentId,
                    UserId = userCommentInteraction.UserId,
                    IsLiked = userCommentInteraction.IsLiked,
                    IsDisliked = userCommentInteraction.IsDisliked,
                    DatabaseEntryAt = userCommentInteraction.DatabaseEntryAt,
                    LastEditedAt = userCommentInteraction.LastEditedAt,
                    Note = userCommentInteraction.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserCommentInteraction",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.gotUserCommentInteractions", new
            {
                userCommentInteractionIds = userCommentInteractions.Select(i => i.Id),
                gotBy = currentUserId
            });

            //Return the userCommentInteractions
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for getting Comment Interactions' count with pagination and search.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get-count")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserCommentInteractionResponseDto>>> GetUserCommentInteractionsCount([FromBody] GetUserCommentInteractionDto dto)
        {
            //Get userCommentInteraction id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserCommentInteractions.Include(i => i.UserComment).AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(i => dto.UserId.Contains(i.UserId));
            }
            if (dto.UserCommentId != null)
            {
                query = query.Where(i => dto.UserCommentId.Contains(i.UserCommentId));
            }
            if (dto.IsLiked != null)
            {
                query = query.Where(i => dto.IsLiked == i.IsLiked);
            }
            if (dto.IsDisliked != null)
            {
                query = query.Where(i => dto.IsDisliked == i.IsDisliked);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(i => i.User).Search(dto.Query, i => i.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userCommentInteractions with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Count the amount of interactions to return
            var interactionsAmount = await query.Where(i => currentUserId == i.UserId || isPrivileged || (i.UserComment != null && currentUserId == i.UserComment.UserId) || (i.UserComment != null && i.UserComment.Build != null && i.UserComment.Build.Status != BuildStatus.DRAFT && i.UserComment.Build.Status != BuildStatus.GENERATED)).CountAsync();

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserCommentInteraction",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                "Operation Successful - UserCommentInteraction Counted"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.gotUserCommentInteractionsCount", new
            {
                count = interactionsAmount,
                gotBy = currentUserId
            });

            //Return the userCommentInteractions
            return Ok(interactionsAmount);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserCommentInteraction for staff.
        /// Used to remove marking that a user interacted with a userComment.
        /// Users can remove marking for their own interactions, while admins can remove them for all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserCommentInteraction(Guid id)
        {
            //Get userCommentInteraction id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userCommentInteraction to delete
            var userCommentInteraction = await _db.UserCommentInteractions.Include(i => i.UserComment).FirstOrDefaultAsync(i => i.Id == id);
            if (userCommentInteraction == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserCommentInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserCommentInteraction"
                );

                //Return not found response
                return NotFound(new { userCommentInteraction = "UserCommentInteraction not found!" });
            }

            //Check if current user is deleting their own userCommentInteraction or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userCommentInteraction.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserCommentInteraction",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Delete the userCommentInteraction
            _db.UserCommentInteractions.Remove(userCommentInteraction);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserCommentInteraction",
                ip,
                userCommentInteraction.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userCommentInteraction.deleted", new
            {
                userCommentInteractionId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { userCommentInteraction = "UserCommentInteraction deleted successfully!" });
        }
    }
}
