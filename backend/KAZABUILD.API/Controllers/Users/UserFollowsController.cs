using KAZABUILD.Application.DTOs.Users.UserActivity;
using KAZABUILD.Application.DTOs.Users.UserFollow;
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
    /// Controller for User Follow related endpoints.
    /// Used to control following based interactions between users.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserFollowsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new UserFollow
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserFollow([FromBody] CreateUserFollowDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Follower and Followed exists
            var Follower = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.FollowerId);
            var Followed = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.FollowedId);
            if (Follower == null || Followed == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Follower or Followed Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Assigned Follower or Followed not found!" });
            }

            //Check if the user isn't already followed
            var isUserFollowAvailable = await _db.UserFollows.FirstOrDefaultAsync(f => f.FollowerId == dto.FollowerId && f.FollowedId == dto.FollowedId);
            if (isUserFollowAvailable != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserFollow",
                    ip,
                    isUserFollowAvailable.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - The selected users are already present in the follows"
                );

                //Return proper conflict response
                return Conflict(new { message = "User already followed!" });
            }

            //Check if current user has staff permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.FollowerId;

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

            //Create a userFollow to add
            UserFollow userFollow = new()
            {
                FollowerId = dto.FollowerId,
                FollowedId = dto.FollowedId,
                FollowedAt = dto.FollowedAt,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userFollow to the database
            _db.UserFollows.Add(userFollow);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserFollow",
                ip,
                userFollow.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserFollow Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.created", new
            {
                userFollowId = userFollow.Id,
                craetedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User followed successfully!", id = userFollow.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserFollow.
        /// Only staff can modify them to add notes.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> UpdateUserFollow(Guid id, [FromBody] UpdateUserFollowDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFollow to edit
            var userFollow = await _db.UserFollows.FirstOrDefaultAsync(f => f.Id == id);
            if (userFollow == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserFollow",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFollow"
                );

                //Return not found response
                return NotFound(new { message = "UserFollow not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userFollow.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userFollow.Note = null;
                else
                    userFollow.Note = dto.Note;
            }

            //Update edit timestamp
            userFollow.LastEditedAt = DateTime.UtcNow;

            //Update the userFollow
            _db.UserFollows.Update(userFollow);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserFollow",
                ip,
                userFollow.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.updated", new
            {
                userFollowId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Follow note updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserFollow specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserFollowResponseDto>> GetUserFollow(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFollow to return
            var userFollow = await _db.UserFollows.FirstOrDefaultAsync(f => f.Id == id);
            if (userFollow == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserFollow",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFollow"
                );

                //Return not found response
                return NotFound(new { message = "User Follow not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserFollowResponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == userFollow.FollowerId;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserFollow",
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

                //Create userFollow response
                response = new UserFollowResponseDto
                {
                    Id = userFollow.Id,
                    FollowedId = userFollow.FollowedId,
                    FollowerId = userFollow.FollowerId,
                    FollowedAt = userFollow.FollowedAt
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userFollow response
                response = new UserFollowResponseDto
                {
                    Id = userFollow.Id,
                    FollowedId = userFollow.FollowedId,
                    FollowerId = userFollow.FollowerId,
                    FollowedAt = userFollow.FollowedAt,
                    DatabaseEntryAt = userFollow.DatabaseEntryAt,
                    LastEditedAt = userFollow.LastEditedAt,
                    Note = userFollow.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFollow",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.got", new
            {
                userFollowId = id,
                gotBy = currentUserId
            });

            //Return the userFollow
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserFollows with pagination,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserFollowResponseDto>>> GetUserFollows([FromBody] GetUserFollowDto dto)
        {
            //Get userFollow id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserFollows.AsNoTracking();

            //Filter by the variables if included
            if (dto.FollowerId != null)
            {
                query = query.Where(f => dto.FollowerId.Contains(f.FollowerId));
            }
            if (dto.FollowedId != null)
            {
                query = query.Where(f => dto.FollowedId.Contains(f.FollowedId));
            }
            if (dto.FollowedAtStart != null)
            {
                query = query.Where(f => f.FollowedAt >= dto.FollowedAtStart);
            }
            if (dto.FollowedAtEnd != null)
            {
                query = query.Where(f => f.FollowedAt <= dto.FollowedAtEnd);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(f => f.Followed).Include(f => f.Follower).Search(dto.Query, i => i.Followed!.DisplayName, i => i.Follower!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userFollows with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserFollow> userFollows = await query.Where(f => f.FollowerId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<UserFollowResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserFollows";

                //Create a userFollow response list
                responses = [.. userFollows.Select(userFollow =>
                {
                    //Return a follow response
                    return new UserFollowResponseDto
                    {
                        Id = userFollow.Id,
                        FollowedId = userFollow.FollowedId,
                        FollowerId = userFollow.FollowerId,
                        FollowedAt = userFollow.FollowedAt
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserFollows";

                //Create a userFollow response list
                responses = [.. userFollows.Select(userFollow => new UserFollowResponseDto
                {
                    Id = userFollow.Id,
                    FollowedId = userFollow.FollowedId,
                    FollowerId = userFollow.FollowerId,
                    FollowedAt = userFollow.FollowedAt,
                    DatabaseEntryAt = userFollow.DatabaseEntryAt,
                    LastEditedAt = userFollow.LastEditedAt,
                    Note = userFollow.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFollow",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.gotUserFollows", new
            {
                userFollowIds = userFollows.Select(f => f.Id),
                gotBy = currentUserId
            });

            //Return the userFollows
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for getting User's follower or followed count with pagination.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get-count")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<int>> GetUserFollowsCount([FromBody] GetUserFollowDto dto)
        {
            //Get userFollow id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserFollows.AsNoTracking();

            //Filter by the variables if included
            if (dto.FollowerId != null && dto.FollowedId == null)
            {
                query = query.Where(f => dto.FollowerId.Contains(f.FollowerId));
            }
            if (dto.FollowedId != null && dto.FollowerId == null)
            {
                query = query.Where(f => dto.FollowedId.Contains(f.FollowedId));
            }
            if (dto.FollowedAtStart != null)
            {
                query = query.Where(f => f.FollowedAt >= dto.FollowedAtStart);
            }
            if (dto.FollowedAtEnd != null)
            {
                query = query.Where(f => f.FollowedAt <= dto.FollowedAtEnd);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(f => f.Followed).Include(f => f.Follower).Search(dto.Query, i => i.Followed!.DisplayName, i => i.Follower!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userFollows with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Count the amount of follows to return
            var followsAmount = await query.CountAsync();

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFollow",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                "Operation Successful - UserFollows Counted"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.gotUserFollowsCount", new
            {
                count = followsAmount,
                gotBy = currentUserId
            });

            //Return the userFollows
            return Ok(followsAmount);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserFollow, i.e. unfollowing.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserFollow(Guid id)
        {
            //Get userFollow id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userFollow to delete
            var userFollow = await _db.UserFollows.FirstOrDefaultAsync(f => f.Id == id);
            if (userFollow == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserFollow",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserFollow"
                );

                //Return not found response
                return NotFound(new { message = "UserFollow not found!" });
            }

            //Check if current user has staff permissions or if they are unfollowing a user
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userFollow.FollowerId;

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

            //Delete the userFollow
            _db.UserFollows.Remove(userFollow);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserFollow",
                ip,
                userFollow.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userFollow.deleted", new
            {
                userFollowId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Unfollowed successfully!" });
        }
    }
}
