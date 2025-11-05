using KAZABUILD.Application.DTOs.Users.Notification;
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
    /// Controller for Notification related endpoints.
    /// The users, administration and the system can all send them.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class NotificationsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new Notification.
        /// Used to send the notifications.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddNotification([FromBody] CreateNotificationDto dto)
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
                    "Notification",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has admin permissions or if they are creating a notification for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Notification",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a notification to add
            Notification notification = new()
            {
                UserId = dto.UserId,
                NotificationType = dto.NotificationType,
                Body = dto.Body,
                Title = dto.Title,
                LinkUrl = dto.LinkUrl,
                SentAt = isPrivileged ? dto.SentAt : DateTime.UtcNow,
                IsRead = dto.IsRead,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the notification to the database
            _db.Notifications.Add(notification);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Notification",
                ip,
                notification.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Notification Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("notification.created", new
            {
                notificationId = notification.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { notification = "Notification sent successfully!", id = notification.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected Notification.
        /// User can modify only whether they read the notification, while staff can modify all fields.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateNotification(Guid id, [FromBody] UpdateNotificationDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the notification to edit
            var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.Id == id);
            //Check if the notification exists
            if (notification == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Notification",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Notification"
                );

                //Return not found response
                return NotFound(new { notification = "Notification not found!" });
            }

            //Check if current user has admin permissions or if they are modifying their own notification
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == notification.UserId;

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
            if (dto.IsRead != null)
            {
                changedFields.Add("IsRead: " + notification.IsRead);

                notification.IsRead = (bool)dto.IsRead;
            }
            if (isPrivileged)
            {
                if (!string.IsNullOrWhiteSpace(dto.Body))
                {
                    changedFields.Add("Body: " + notification.Body);

                    notification.Body = dto.Body;
                }
                if (!string.IsNullOrWhiteSpace(dto.Title))
                {
                    changedFields.Add("Title: " + notification.Title);

                    notification.Title = dto.Title;
                }
                if (dto.LinkUrl != null)
                {
                    changedFields.Add("LinkUrl: " + notification.LinkUrl);

                    if (string.IsNullOrWhiteSpace(dto.LinkUrl))
                        notification.LinkUrl = null;
                    else
                        notification.LinkUrl = dto.LinkUrl;
                }
                if (dto.SentAt != null)
                {
                    changedFields.Add("SentAt: " + notification.SentAt);

                    notification.SentAt = (DateTime)dto.SentAt;
                }
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + notification.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        notification.Note = null;
                    else
                        notification.Note = dto.Note;
                }
            }

            //Update edit timestamp
            notification.LastEditedAt = DateTime.UtcNow;

            //Update the notification
            _db.Notifications.Update(notification);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Notification",
                ip,
                notification.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("notification.updated", new
            {
                notificationId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { notification = "Notification updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Notification specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<NotificationResponseDto>> GetNotification(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the notification to return
            var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.Id == id);
            if (notification == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Notification",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Notification"
                );

                //Return not found response
                return NotFound(new { notification = "Notification not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            NotificationResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isSelf = currentUserId == notification.UserId;
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Notification",
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

                //Create notification response
                response = new NotificationResponseDto
                {
                    Id = notification.Id,
                    UserId = notification.UserId,
                    NotificationType = notification.NotificationType,
                    Body = notification.Body,
                    Title = notification.Title,
                    LinkUrl = notification.LinkUrl,
                    SentAt = notification.SentAt,
                    IsRead = notification.IsRead
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create notification response
                response = new NotificationResponseDto
                {
                    Id = notification.Id,
                    UserId = notification.UserId,
                    NotificationType = notification.NotificationType,
                    Body = notification.Body,
                    Title = notification.Title,
                    LinkUrl = notification.LinkUrl,
                    SentAt = notification.SentAt,
                    IsRead = notification.IsRead,
                    DatabaseEntryAt = notification.DatabaseEntryAt,
                    LastEditedAt = notification.LastEditedAt,
                    Note = notification.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Notification",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("notification.got", new
            {
                notificationId = id,
                gotBy = currentUserId
            });

            //Return the notification
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Notifications with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<NotificationResponseDto>>> GetNotifications([FromBody] GetNotificationDto dto)
        {
            //Get notification id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Notifications.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(n => dto.UserId.Contains(n.UserId));
            }
            if (dto.NotificationType != null)
            {
                query = query.Where(n => dto.NotificationType.Contains(n.NotificationType));
            }
            if (dto.IsRead != null)
            {
                query = query.Where(n => n.IsRead == dto.IsRead);
            }
            if (dto.SentAtStart != null)
            {
                query = query.Where(n => n.SentAt >= dto.SentAtEnd);
            }
            if (dto.SentAtEnd != null)
            {
                query = query.Where(n => n.SentAt <= dto.SentAtEnd);
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, n => n.SentAt, n => n.Title, n => n.Body);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get notifications with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<Notification> notifications = await query.Where(n => n.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<NotificationResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Notifications";

                //Create a notification response list
                responses = [.. notifications.Select(notification =>
                {
                    //Return a follow response
                    return new NotificationResponseDto
                    {
                        Id = notification.Id,
                        UserId = notification.UserId,
                        NotificationType = notification.NotificationType,
                        Body = notification.Body,
                        Title = notification.Title,
                        LinkUrl = notification.LinkUrl,
                        SentAt = notification.SentAt,
                        IsRead = notification.IsRead
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Notifications";

                //Create a notification response list
                responses = [.. notifications.Select(notification => new NotificationResponseDto
                {
                    Id = notification.Id,
                    UserId = notification.UserId,
                    NotificationType = notification.NotificationType,
                    Body = notification.Body,
                    Title = notification.Title,
                    LinkUrl = notification.LinkUrl,
                    SentAt = notification.SentAt,
                    IsRead = notification.IsRead,
                    DatabaseEntryAt = notification.DatabaseEntryAt,
                    LastEditedAt = notification.LastEditedAt,
                    Note = notification.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Notification",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("notification.gotNotifications", new
            {
                notificationIds = notifications.Select(n => n.Id),
                gotBy = currentUserId
            });

            //Return the notifications
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Notifications.
        /// The users can delete their own Notifications, administration can delete all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteNotification(Guid id)
        {
            //Get notification id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the notification to delete
            var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.Id == id);
            if (notification == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Notification",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Notification"
                );

                //Return not found response
                return NotFound(new { notification = "Notification not found!" });
            }

            //Check if current user has admin permissions or if they are creating a notification for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == notification.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Notification",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Delete the notification
            _db.Notifications.Remove(notification);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Notification",
                ip,
                notification.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("notification.deleted", new
            {
                notificationId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { notification = "Notification deleted successfully!" });
        }
    }
}
