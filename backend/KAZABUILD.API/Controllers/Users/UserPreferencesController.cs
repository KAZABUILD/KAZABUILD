using KAZABUILD.Application.DTOs.Users.UserPreference;
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
    //Controller for User Preference related endpoints
    [ApiController]
    [Route("[controller]")]
    public class UserPreferencesController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        //API Endpoint for creating a new UserPreference
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserPreference([FromBody] CreateUserPreferenceDto dto)
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
                    "UserPreference",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has staff permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserPreference",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userPreference to add
            UserPreference userPreference = new()
            {
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userPreference to the database
            _db.UserPreferences.Add(userPreference);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserPreference",
                ip,
                userPreference.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserPreference Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreference.created", new
            {
                userPreferenceId = userPreference.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Preference created successfully!", id = userPreference.Id });
        }

        //API endpoint for updating the selected UserPreference
        //User can modify only their own Preferences,
        //while admins can modify all
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateUserPreference(Guid id, [FromBody] UpdateUserPreferenceDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreference to edit
            var userPreference = await _db.UserPreferences.FirstOrDefaultAsync(u => u.Id == id);
            if (userPreference == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserPreference",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreference"
                );

                //Return not found response
                return NotFound(new { message = "User Preference not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userPreference.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userPreference.Note = null;
                else
                    userPreference.Note = dto.Note;
            }

            //Update edit timestamp
            userPreference.LastEditedAt = DateTime.UtcNow;

            //Update the userPreference
            _db.UserPreferences.Update(userPreference);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserPreference",
                ip,
                userPreference.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreference.updated", new
            {
                userPreferenceId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Preference updated successfully!" });
        }

        //API endpoint for getting the UserPreference specified by id,
        //different level of information returned based on privileges
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserPreferenceResponseDto>> GetUserPreference(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreference to return
            var userPreference = await _db.UserPreferences.FirstOrDefaultAsync(u => u.Id == id);
            if (userPreference == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserPreference",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreference"
                );

                //Return not found response
                return NotFound(new { message = "User Preference not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserPreferenceResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isSelf = currentUserId == userPreference.UserId;
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserPreference",
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

                //Create userPreference response
                response = new UserPreferenceResponseDto
                {
                    Id = userPreference.Id,
                    UserId = userPreference.UserId
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userPreference response
                response = new UserPreferenceResponseDto
                {
                    Id = userPreference.Id,
                    UserId = userPreference.UserId,
                    DatabaseEntryAt = userPreference.DatabaseEntryAt,
                    LastEditedAt = userPreference.LastEditedAt,
                    Note = userPreference.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserPreference",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreference.got", new
            {
                userPreferenceId = id,
                gotBy = currentUserId
            });

            //Return the userPreference
            return Ok(response);
        }

        //API endpoint for getting UserPreferences with pagination and search,
        //different level of information returned based on privileges
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserPreferenceResponseDto>>> GetUserPreferences([FromBody] GetUserPreferenceDto dto)
        {
            //Get userPreference id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserPreferences.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(p => dto.UserId.Contains(p.UserId));
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                //query = query.Search(dto.Query, );
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userPreferences with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserPreference> userPreferences = await query.Where(f => f.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<UserPreferenceResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserPreferences";

                //Create a userPreference response list
                responses = [.. userPreferences.Select(userPreference =>
                {
                    //Return a follow response
                    return new UserPreferenceResponseDto
                    {
                        Id = userPreference.Id,
                        UserId = userPreference.UserId
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserPreferences";

                //Create a userPreference response list
                responses = [.. userPreferences.Select(userPreference => new UserPreferenceResponseDto
                {
                    Id = userPreference.Id,
                    UserId = userPreference.UserId,
                    DatabaseEntryAt = userPreference.DatabaseEntryAt,
                    LastEditedAt = userPreference.LastEditedAt,
                    Note = userPreference.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserPreference",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreference.gotUserPreferences", new
            {
                userPreferenceIds = userPreferences.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the userPreferences
            return Ok(responses);
        }

        //API endpoint for deleting the selected UserPreference for administration
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserPreference(Guid id)
        {
            //Get userPreference id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreference to delete
            var userPreference = await _db.UserPreferences.FirstOrDefaultAsync(u => u.Id == id);
            if (userPreference == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserPreference",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreference"
                );

                //Return not found response
                return NotFound(new { message = "UserPreference not found!" });
            }

            //Check if current user has staff permissions or if they are deleting their own preference
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userPreference.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserPreference",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Delete the userPreference
            _db.UserPreferences.Remove(userPreference);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserPreference",
                ip,
                userPreference.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreference.deleted", new
            {
                userPreferenceId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserPreference deleted successfully!" });
        }
    }
}
