using KAZABUILD.Application.DTOs.Users.UserActivity;
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
    /// Controller for UserActivity related endpoints.
    /// User Activity means anything that the user does in the frontend.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    /// <param name="cache"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserActivitiesController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher, IMemoryCache cache) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IMemoryCache _cache = cache;

        /// <summary>
        /// API Endpoint for logging new User Activity.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserActivity([FromBody] CreateUserActivityDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the User exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == currentUserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserActivity",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has admin permissions for date assignment
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Create a userActivity to add
            UserActivity userActivity = new()
            {
                UserId = currentUserId,
                ActivityType = dto.ActivityType,
                TargetId = dto.TargetId,
                Timestamp = isPrivileged ? dto.Timestamp : DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userActivity to the database
            _db.UserActivities.Add(userActivity);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserActivity",
                ip,
                userActivity.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserActivity Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.created", new
            {
                userActivityId = userActivity.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User activity logged successfully!", id = userActivity.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected User Activity's Note for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateUserActivity(Guid id, [FromBody] UpdateUserActivityDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userActivity to edit
            var userActivity = await _db.UserActivities.FirstOrDefaultAsync(a => a.Id == id);
            //Check if the userActivity exists
            if (userActivity == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserActivity",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserActivity"
                );

                //Return not found response
                return NotFound(new { message = "UserActivity not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update the note
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userActivity.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userActivity.Note = null;
                else
                    userActivity.Note = dto.Note;
            }

            //Update edit timestamp
            userActivity.LastEditedAt = DateTime.UtcNow;

            //Update the userActivity
            _db.UserActivities.Update(userActivity);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserActivity",
                ip,
                userActivity.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.updated", new
            {
                userActivityId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Activity updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserActivity specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserActivityResponseDto>> GetUserActivity(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userActivity to return
            var userActivity = await _db.UserActivities.FirstOrDefaultAsync(a => a.Id == id);
            if (userActivity == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserActivity",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserActivity"
                );

                //Return not found response
                return NotFound(new { message = "UserActivity not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserActivityResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userActivity response
                response = new UserActivityResponseDto
                {
                    Id = userActivity.Id,
                    UserId = userActivity.UserId,
                    ActivityType = userActivity.ActivityType,
                    TargetId = userActivity.TargetId,
                    Timestamp = userActivity.Timestamp
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userActivity response
                response = new UserActivityResponseDto
                {
                    Id = userActivity.Id,
                    UserId = userActivity.UserId,
                    ActivityType = userActivity.ActivityType,
                    TargetId = userActivity.TargetId,
                    Timestamp = userActivity.Timestamp,
                    DatabaseEntryAt = userActivity.DatabaseEntryAt,
                    LastEditedAt = userActivity.LastEditedAt,
                    Note = userActivity.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserActivity",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.got", new
            {
                userActivityId = id,
                gotBy = currentUserId
            });

            //Return the userActivity
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserActivities with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserActivityResponseDto>>> GetUserActivities([FromBody] GetUserActivityDto dto)
        {
            //Get userActivity id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserActivities.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(a => dto.UserId.Contains(a.UserId));
            }
            if (dto.ActivityType != null)
            {
                query = query.Where(a => a.ActivityType != null && dto.ActivityType.Contains(a.ActivityType));
            }
            if (dto.TargetId != null)
            {
                query = query.Where(a => dto.TargetId.Contains(a.TargetId));
            }
            if (dto.TimestampStart != null)
            {
                query = query.Where(a => a.Timestamp >= dto.TimestampStart);
            }
            if (dto.TimestampEnd != null)
            {
                query = query.Where(a => a.Timestamp <= dto.TimestampEnd);
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(a => a.User).Search(dto.Query, a => a.ActivityType, a => a.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userActivities with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            //Get all queried userActivities as a list
            List<UserActivity> userActivities = await query.ToListAsync();

            //Declare response variable
            List<UserActivityResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserActivities";

                //Create a userActivity response list
                responses = [.. userActivities.Select(userActivity =>
                {
                    //Create a response
                    return new UserActivityResponseDto
                    {
                        Id = userActivity.Id,
                        UserId = userActivity.UserId,
                        ActivityType = userActivity.ActivityType,
                        TargetId = userActivity.TargetId,
                        Timestamp = userActivity.Timestamp
                    };
                })];

            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserActivities";

                //Create a userActivity response list
                responses = [.. userActivities.Select(userActivity =>
                {
                    //Create a response
                    return new UserActivityResponseDto
                    {
                        Id = userActivity.Id,
                        UserId = userActivity.UserId,
                        ActivityType = userActivity.ActivityType,
                        TargetId = userActivity.TargetId,
                        Timestamp = userActivity.Timestamp,
                        DatabaseEntryAt = userActivity.DatabaseEntryAt,
                        LastEditedAt = userActivity.LastEditedAt,
                        Note = userActivity.Note
                    };
                })];
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserActivity",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.gotUserActivities", new
            {
                userActivityIds = userActivities.Select(a => a.Id),
                gotBy = currentUserId
            });

            //Return the userActivities
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for getting UserActivities view count with pagination and search.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get-count")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<int>> GetUserActivitiesCount([FromBody] GetUserActivityDto dto)
        {
            //Get userActivity id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Generate a cache key
            var cacheKey = CacheHelper.GetUserActivityCountCacheKey(dto);

            //Try to get the views from cache first
            if (_cache.TryGetValue(cacheKey, out int cachedViews))
            {
                //Log success
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserActivity",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.INFORMATION,
                    "Operation Successful - UserActivity Count Got From Cache"
                );

                //Return the views amount
                return Ok(cachedViews);
            }

            //Declare the query
            var query = _db.UserActivities.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(a => dto.UserId.Contains(a.UserId));
            }
            if (dto.ActivityType != null)
            {
                query = query.Where(a => a.ActivityType != null && dto.ActivityType.Contains(a.ActivityType));
            }
            if (dto.TargetId != null)
            {
                query = query.Where(a => dto.TargetId.Contains(a.TargetId));
            }
            if (dto.TimestampStart != null)
            {
                query = query.Where(a => a.Timestamp >= dto.TimestampStart);
            }
            if (dto.TimestampEnd != null)
            {
                query = query.Where(a => a.Timestamp <= dto.TimestampEnd);
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(a => a.User).Search(dto.Query, a => a.ActivityType, a => a.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userActivities with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Count the amount of activities to return as views
            var views = await query.CountAsync();

            //Cache the query result
            _cache.Set(cacheKey, views, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1)
            });

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserActivity",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                "Operation Successful - UserActivity Counted"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.gotUserActivitiesCount", new
            {
                count = views,
                gotBy = currentUserId
            });

            //Return the views amount
            return Ok(views);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserActivity.
        /// Users can delete userActivities they sent and staff can delete all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteUserActivity(Guid id)
        {
            //Get userActivity id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userActivity to delete
            var userActivity = await _db.UserActivities.FirstOrDefaultAsync(a => a.Id == id);
            if (userActivity == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserActivity",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserActivity"
                );

                //Return not found response
                return NotFound(new { message = "UserActivity not found!" });
            }

            //Delete the userActivity
            _db.UserActivities.Remove(userActivity);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the deletion
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserActivity",
                ip,
                userActivity.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userActivity.deleted", new
            {
                userActivityId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserActivity deleted successfully!" });
        }
    }
}
