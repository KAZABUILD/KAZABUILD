using KAZABUILD.Application.DTOs.Users.UserBlock;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    /// <summary>
    /// Controller for User Block related endpoints.
    /// Used to control blocking based interactions between users.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    /// <param name="cache"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserBlocksController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher, IMemoryCache cache) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IMemoryCache _cache = cache;

        /// <summary>
        /// API Endpoint for creating a new UserBlock.
        /// Allows Users to block other users.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserBlock([FromBody] CreateUserBlockDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Blocked and Blocking User exist
            var Blocked = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.BlockedUserId);
            var Blocking = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (Blocked == null || Blocking == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Blocked Or Blocking User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Assigned Blocked or Blocking User not found!" });
            }

            //Check if the user isn't already blocked
            var isUserBlockAvailable = await _db.UserBlocks.FirstOrDefaultAsync(f => f.BlockedUserId == dto.BlockedUserId && f.UserId == dto.UserId);
            if (isUserBlockAvailable != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserBlock",
                    ip,
                    isUserBlockAvailable.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - The selected users are already present in the follows"
                );

                //Return proper conflict response
                return Conflict(new { message = "User already followed!" });
            }

            //Check if current user has staff permissions or if they are creating a block for themselves
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserBlock",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userBlock to add
            UserBlock userBlock = new()
            {
                BlockedUserId = dto.BlockedUserId,
                UserId = dto.UserId,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userBlock to the database
            _db.UserBlocks.Add(userBlock);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserBlock",
                ip,
                userBlock.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserBlock Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userBlock.created", new
            {
                userBlockId = userBlock.Id,
                craetedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User followed successfully!", id = userBlock.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserBlock.
        /// Only staff can modify them to add notes.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> UpdateUserBlock(Guid id, [FromBody] UpdateUserBlockDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userBlock to edit
            var userBlock = await _db.UserBlocks.FirstOrDefaultAsync(f => f.Id == id);
            if (userBlock == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserBlock",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserBlock"
                );

                //Return not found response
                return NotFound(new { message = "UserBlock not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userBlock.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userBlock.Note = null;
                else
                    userBlock.Note = dto.Note;
            }

            //Update edit timestamp
            userBlock.LastEditedAt = DateTime.UtcNow;

            //Update the userBlock
            _db.UserBlocks.Update(userBlock);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserBlock",
                ip,
                userBlock.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userBlock.updated", new
            {
                userBlockId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Follow note updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserBlock specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserBlockResponseDto>> GetUserBlock(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userBlock to return
            var userBlock = await _db.UserBlocks.FirstOrDefaultAsync(f => f.Id == id);
            if (userBlock == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserBlock",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserBlock"
                );

                //Return not found response
                return NotFound(new { message = "User Follow not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserBlockResponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == userBlock.UserId;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserBlock",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userBlock response
                response = new UserBlockResponseDto
                {
                    Id = userBlock.Id,
                    BlockedUserId = userBlock.UserId,
                    UserId = userBlock.Id
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userBlock response
                response = new UserBlockResponseDto
                {
                    Id = userBlock.Id,
                    BlockedUserId = userBlock.UserId,
                    UserId = userBlock.Id,
                    DatabaseEntryAt = userBlock.DatabaseEntryAt,
                    LastEditedAt = userBlock.LastEditedAt,
                    Note = userBlock.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserBlock",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userBlock.got", new
            {
                userBlockId = id,
                gotBy = currentUserId
            });

            //Return the userBlock
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserBlocks with pagination,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserBlockResponseDto>>> GetUserBlocks([FromBody] GetUserBlockDto dto)
        {
            //Get userBlock id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserBlocks.AsNoTracking();

            //Filter by the variables if included
            if (dto.BlockedUserId != null)
            {
                query = query.Where(f => dto.BlockedUserId.Contains(f.BlockedUserId));
            }
            if (dto.UserId != null)
            {
                query = query.Where(f => dto.UserId.Contains(f.UserId));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(f => f.BlockedUser).Include(f => f.User).Search(dto.Query, i => i.BlockedUser!.DisplayName, i => i.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userBlocks with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserBlock> userBlocks = await query.Where(f => f.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<UserBlockResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserBlocks";

                //Create a userBlock response list
                responses = [.. userBlocks.Select(userBlock =>
                {
                    //Return a follow response
                    return new UserBlockResponseDto
                    {
                        Id = userBlock.Id,
                        BlockedUserId = userBlock.UserId,
                        UserId = userBlock.Id
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserBlocks";

                //Create a userBlock response list
                responses = [.. userBlocks.Select(userBlock => new UserBlockResponseDto
                {
                    Id = userBlock.Id,
                    BlockedUserId = userBlock.UserId,
                    UserId = userBlock.Id,
                    DatabaseEntryAt = userBlock.DatabaseEntryAt,
                    LastEditedAt = userBlock.LastEditedAt,
                    Note = userBlock.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserBlock",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userBlock.gotUserBlocks", new
            {
                userBlockIds = userBlocks.Select(f => f.Id),
                gotBy = currentUserId
            });

            //Return the userBlocks
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserBlock, i.e. unfollowing.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserBlock(Guid id)
        {
            //Get userBlock id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userBlock to delete
            var userBlock = await _db.UserBlocks.FirstOrDefaultAsync(f => f.Id == id);
            if (userBlock == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserBlock",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserBlock"
                );

                //Return not found response
                return NotFound(new { message = "UserBlock not found!" });
            }

            //Check if current user has staff permissions or if they are unblocking a user they blocked
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userBlock.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserBlock",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Delete the userBlock
            _db.UserBlocks.Remove(userBlock);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserBlock",
                ip,
                userBlock.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userBlock.deleted", new
            {
                userBlockId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Unfollowed successfully!" });
        }
    }
}
