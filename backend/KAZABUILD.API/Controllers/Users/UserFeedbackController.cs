using KAZABUILD.Application.DTOs.Users.UserFeedback;
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
    /// Controller for Feedback related endpoints.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserFeedbackController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for leaving feedback.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserFeedback([FromBody] CreateUserFeedbackDto dto)
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
                    "UserFeedback",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has staff permissions or if they are creating a forum post for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserFeedback",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userFeedback to add
            UserFeedback userFeedback = new()
            {
                UserId = dto.UserId,
                Feedback = dto.Feedback,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userFeedback to the database
            _db.UserFeedback.Add(userFeedback);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserFeedback",
                ip,
                userFeedback.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserFeedback Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFeedback.created", new
            {
                userFeedbackId = userFeedback.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Feedback left successfully!", id = userFeedback.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserFeedback
        /// User can modify only their own posts, while staff can modify all.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUserFeedback(Guid id, [FromBody] UpdateUserFeedbackDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFeedback to edit
            var userFeedback = await _db.UserFeedback.FirstOrDefaultAsync(f => f.Id == id);
            //Check if the userFeedback exists
            if (userFeedback == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserFeedback",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFeedback"
                );

                //Return not found response
                return NotFound(new { message = "Feedback not found!" });
            }

            //Check if current user has staff permissions or if they are modifying their own feedback
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userFeedback.UserId;

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
            if (dto.UserId != null)
            {
                changedFields.Add("UserId: " + userFeedback.UserId);

                userFeedback.UserId = (Guid)dto.UserId;
            }
            if (!string.IsNullOrWhiteSpace(dto.Feedback))
            {
                changedFields.Add("Feedback: " + userFeedback.Feedback);

                userFeedback.Feedback = dto.Feedback;
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + userFeedback.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        userFeedback.Note = null;
                    else
                        userFeedback.Note = dto.Note;
                }
            }

            //Update edit timestamp
            userFeedback.LastEditedAt = DateTime.UtcNow;

            //Update the userFeedback
            _db.UserFeedback.Update(userFeedback);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserFeedback",
                ip,
                userFeedback.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFeedback.updated", new
            {
                userFeedbackId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Feedback updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserFeedback specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserFeedbackResponseDto>> GetUserFeedback(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFeedback to return
            var userFeedback = await _db.UserFeedback.FirstOrDefaultAsync(f => f.Id == id);
            if (userFeedback == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserFeedback",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFeedback"
                );

                //Return not found response
                return NotFound(new { message = "Feedback not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserFeedbackResponseDto response;

            //Check if current user has staff permissions or if they are modifying their own feedback
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userFeedback.UserId;

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

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userFeedback response
                response = new UserFeedbackResponseDto
                {
                    Id = userFeedback.Id,
                    UserId = userFeedback.UserId,
                    Feedback = userFeedback.Feedback
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userFeedback response
                response = new UserFeedbackResponseDto
                {
                    Id = userFeedback.Id,
                    UserId = userFeedback.UserId,
                    Feedback = userFeedback.Feedback,
                    DatabaseEntryAt = userFeedback.DatabaseEntryAt,
                    LastEditedAt = userFeedback.LastEditedAt,
                    Note = userFeedback.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFeedback",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFeedback.got", new
            {
                userFeedbackId = id,
                gotBy = currentUserId
            });

            //Return the userFeedback
            return Ok(response);
        }

        /// <summary>
        ///  API endpoint for getting UserFeedback with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserFeedbackResponseDto>>> GetUserFeedback([FromBody] GetUserFeedbackDto dto)
        {
            //Get userFeedback id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserFeedback.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(f => dto.UserId.Contains(f.UserId));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(f => f.User).Search(dto.Query, f => f.Feedback, f => f.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userFeedback with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserFeedback> userFeedback = await query.Where(f => f.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<UserFeedbackResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserFeedback";

                //Create a userFeedback response list
                responses = [.. userFeedback.Select(userFeedback =>
                {
                    //Return a follow response
                    return new UserFeedbackResponseDto
                    {
                        Id = userFeedback.Id,
                        UserId = userFeedback.UserId,
                        Feedback = userFeedback.Feedback
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserFeedback";

                //Create a userFeedback response list
                responses = [.. userFeedback.Select(userFeedback => new UserFeedbackResponseDto
                {
                    Id = userFeedback.Id,
                    UserId = userFeedback.UserId,
                    Feedback = userFeedback.Feedback,
                    DatabaseEntryAt = userFeedback.DatabaseEntryAt,
                    LastEditedAt = userFeedback.LastEditedAt,
                    Note = userFeedback.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFeedback",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFeedback.gotUserFeedback", new
            {
                userFeedbackIds = userFeedback.Select(f => f.Id),
                gotBy = currentUserId
            });

            //Return the userFeedback
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserFeedback.
        /// Users can delete their own feedback, while staff can delete all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserFeedback(Guid id)
        {
            //Get userFeedback id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFeedback to delete
            var userFeedback = await _db.UserFeedback.FirstOrDefaultAsync(f => f.Id == id);
            if (userFeedback == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserFeedback",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFeedback"
                );

                //Return not found response
                return NotFound(new { message = "UserFeedback not found!" });
            }

            //Check if current user has staff permissions or if they are deleting their own post
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userFeedback.UserId;

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

            //Delete the userFeedback
            _db.UserFeedback.Remove(userFeedback);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserFeedback",
                ip,
                userFeedback.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFeedback.deleted", new
            {
                userFeedbackId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserFeedback deleted successfully!" });
        }
    }
}
