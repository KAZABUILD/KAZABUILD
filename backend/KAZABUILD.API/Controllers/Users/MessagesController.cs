using KAZABUILD.Application.DTOs.Users.Message;
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
    /// Controller for Message related endpoints.
    /// Messages can be sent between all users, staff, system and bots.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class MessagesController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for sending a new Message.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddMessage([FromBody] CreateMessageDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Receiver and Sender exists
            var sender = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.SenderId);
            var receiver = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.SenderId);
            if (receiver == null || sender == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Receiver or Sender Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Assigned receiver or sender not found!" });
            }

            //Check if current user has admin permissions or if they are creating a message for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.SenderId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a message to add
            Message message = new()
            {
                SenderId = dto.SenderId,
                ReceiverId = dto.ReceiverId,
                Content = dto.Content, 
                Title = dto.Title,
                SentAt = dto.SentAt,
                IsRead = dto.IsRead,
                ParentMessageId = dto.ParentMessageId,
                MessageType = dto.MessageType,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the message to the database
            _db.Messages.Add(message);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Message",
                ip,
                message.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Message Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("message.created", new
            {
                messageId = message.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Message sent successfully!", id = message.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected Message
        /// User can modify only if the Messages they received were read, while staff can modify all.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateMessage(Guid id, [FromBody] UpdateMessageDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the message to edit
            var message = await _db.Messages.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the message exists
            if (message == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Message",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Message"
                );

                //Return not found response
                return NotFound(new { message = "Message not found!" });
            }

            //Check if current user has admin permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == message.ReceiverId;

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
                changedFields.Add("IsRead: " + message.IsRead);

                message.IsRead = (bool)dto.IsRead;
            }
            if (isPrivileged)
            {
                if (!string.IsNullOrWhiteSpace(dto.Content))
                {
                    changedFields.Add("Content: " + message.Content);

                    message.Content = dto.Content;
                }
                if (!string.IsNullOrWhiteSpace(dto.Title))
                {
                    changedFields.Add("Title: " + message.Title);

                    message.Title = dto.Title;
                }
                if (dto.SentAt != null)
                {
                    changedFields.Add("SentAt: " + message.SentAt);

                    message.SentAt = (DateTime)dto.SentAt;
                }
                if (dto.ParentMessageId != null)
                {
                    changedFields.Add("ParentMessageId: " + message.ParentMessageId);

                    if (dto.ParentMessageId == Guid.Empty)
                        message.ParentMessageId = null;
                    else
                        message.ParentMessageId = dto.ParentMessageId;
                }
                if (dto.MessageType != null)
                {
                    changedFields.Add("MessageType: " + message.MessageType);

                    message.MessageType = (MessageType)dto.MessageType;
                }
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + message.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        message.Note = null;
                    else
                        message.Note = dto.Note;
                }
            }

            //Update edit timestamp
            message.LastEditedAt = DateTime.UtcNow;

            //Update the message
            _db.Messages.Update(message);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Message",
                ip,
                message.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("message.updated", new
            {
                messageId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Message updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Message specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<MessageResponseDto>> GetMessage(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the message to return
            var message = await _db.Messages.FirstOrDefaultAsync(u => u.Id == id);
            if (message == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Message",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Message"
                );

                //Return not found response
                return NotFound(new { message = "Message not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            MessageResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isSelf = currentUserId == message.SenderId;
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Message",
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

                //Create message response
                response = new MessageResponseDto
                {
                    Id = message.Id,
                    SenderId = message.SenderId,
                    ReceiverId = message.ReceiverId,
                    Content = message.Content,
                    Title = message.Title,
                    SentAt = message.SentAt,
                    IsRead = message.IsRead
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create message response
                response = new MessageResponseDto
                {
                    Id = message.Id,
                    SenderId = message.SenderId,
                    ReceiverId = message.ReceiverId,
                    Content = message.Content,
                    Title = message.Title,
                    SentAt = message.SentAt,
                    IsRead = message.IsRead,
                    DatabaseEntryAt = message.DatabaseEntryAt,
                    LastEditedAt = message.LastEditedAt,
                    Note = message.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Message",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("message.got", new
            {
                messageId = id,
                gotBy = currentUserId
            });

            //Return the message
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Messages with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<MessageResponseDto>>> GetMessages([FromBody] GetMessageDto dto)
        {
            //Get message id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Messages.AsNoTracking();

            //Filter by the variables if included
            if (dto.SenderId != null)
            {
                query = query.Where(m => dto.SenderId.Contains(m.SenderId));
            }
            if (dto.ReceiverId != null)
            {
                query = query.Where(m => dto.ReceiverId.Contains(m.ReceiverId));
            }
            if (dto.IsRead != null)
            {
                query = query.Where(m => m.IsRead == dto.IsRead);
            }
            if (dto.ParentMessageId != null)
            {
                query = query.Where(m => m.ParentMessageId != null && dto.ParentMessageId.Contains((Guid)m.ParentMessageId));
            }
            if (dto.SentAtStart != null)
            {
                query = query.Where(m => m.SentAt >= dto.SentAtEnd);
            }
            if (dto.SentAtEnd != null)
            {
                query = query.Where(m => m.SentAt <= dto.SentAtEnd);
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(m => m.Sender).Search(dto.Query, m => m.SentAt, m => m.Title, m => m.Content, m => m.Sender!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get messages with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<Message> messages = await query.Where(m => m.SenderId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<MessageResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Messages";

                //Create a message response list
                responses = [.. messages.Select(message =>
                {
                    //Return a follow response
                    return new MessageResponseDto
                    {
                        Id = message.Id,
                        SenderId = message.SenderId,
                        ReceiverId = message.ReceiverId,
                        Content = message.Content,
                        Title = message.Title,
                        SentAt = message.SentAt,
                        IsRead = message.IsRead
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Messages";

                //Create a message response list
                responses = [.. messages.Select(message => new MessageResponseDto
                {
                    Id = message.Id,
                    SenderId = message.SenderId,
                    ReceiverId = message.ReceiverId,
                    Content = message.Content,
                    Title = message.Title,
                    SentAt = message.SentAt,
                    IsRead = message.IsRead,
                    DatabaseEntryAt = message.DatabaseEntryAt,
                    LastEditedAt = message.LastEditedAt,
                    Note = message.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Message",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("message.gotMessages", new
            {
                messageIds = messages.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the messages
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Message.
        /// Users can delete messages they sent and staff can delete all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteMessage(Guid id)
        {
            //Get message id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the message to delete
            var message = await _db.Messages.FirstOrDefaultAsync(u => u.Id == id);
            if (message == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Message",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Message"
                );

                //Return not found response
                return NotFound(new { message = "Message not found!" });
            }

            //Check if current user has admin permissions or if they are deleting their own post
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == message.SenderId;

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

            //Delete the message
            _db.Messages.Remove(message);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Message",
                ip,
                message.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("message.deleted", new
            {
                messageId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Message deleted successfully!" });
        }
    }
}
