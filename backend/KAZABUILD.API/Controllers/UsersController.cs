using KAZABUILD.Application.DTOs.User;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using ILogger = KAZABUILD.Application.Interfaces.ILogger;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Application.Helpers;

namespace KAZABUILD.API.Controllers
{
    //Controller for user related endpoints
    [ApiController]
    [Route("[controller]")]
    // [EnableRateLimiting("Fixed")] <- Uncomment to add rate limiting
    public class UsersController(KAZABUILDDBContext db, ILogger logger, IHashingService hasher, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILogger _logger = logger;
        private readonly IHashingService _hasher = hasher;
        private readonly IRabbitMQPublisher _publisher = publisher;

        //Create a new user
        [HttpPost("Add")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> AddUser([FromBody] CreateUserDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Create a user to add
            User user = new()
            {
                Login = dto.Login,
                Email = dto.Email,
                DisplayName = dto.DisplayName,
                PhoneNumber = dto.PhoneNumber,
                Description = dto.Description,
                Gender = dto.Gender,
                UserRole = dto.UserRole,
                ImageUrl = dto.ImageUrl,
                RegisteredAt = dto.RegisteredAt,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the user to the database
            _db.Users.Add(user);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the craetion
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "User",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New User Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.created", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User craeted successfully!" });
        }

        //Update the selected user
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user is editing themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Return unathorized access exception if the user does not have the correct permiossions
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "UPDATE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - Unathorized Access"
                );

                return Forbid();
            }

            //Get the user to edit
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "UPDATE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrEmpty(dto.DisplayName))
            {
                user.DisplayName = dto.DisplayName;

                changedFields.Add("DisplayName: " + dto.DisplayName);
            }
            if (dto.PhoneNumber != null)
            {
                user.PhoneNumber = dto.PhoneNumber;

                changedFields.Add("PhoneNumber: " + dto.PhoneNumber);
            }
            if (dto.Description != null)
            {
                user.Description = dto.Description;

                changedFields.Add("Description: " + dto.Description);
            }
            if (!string.IsNullOrEmpty(dto.Gender))
            {
                user.Gender = dto.Gender;

                changedFields.Add("Gender: " + dto.Gender);
            }
            if (!string.IsNullOrEmpty(dto.ImageUrl))
            {
                user.ImageUrl = dto.ImageUrl;

                changedFields.Add("ImageUrl: " + dto.ImageUrl);
            }

            //Update allowed fields - administration
            if (isPrivileged)
            {
                if (!string.IsNullOrEmpty(dto.Email))
                {
                    user.Email = dto.Email;

                    changedFields.Add("Email: " + dto.Email);
                }
                if (!string.IsNullOrEmpty(dto.Login))
                {
                    user.Login = dto.Login;

                    changedFields.Add("Login: " +  dto.Login);
                }
                if (dto.UserRole != null && !string.IsNullOrEmpty(dto.UserRole.ToString())) user.UserRole = (UserRole)dto.UserRole;
                //Hash password if provided
                if (!string.IsNullOrEmpty(dto.Password))
                {
                    user.PasswordHash = _hasher.Hash(dto.Password);

                    changedFields.Add("Changed Password");
                }
            }

            //Update edit timestamp
            user.LastEditedAt = DateTime.UtcNow;

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "UPDATE",
                "User",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.updated", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User updated successfully!" });
        }

        //Get the selected user
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserReponseDto>> GetUser(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the user to return
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.got", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            //Declare response variable
            UserReponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check what permissions user has and return respective information
            if (!isSelf && !isPrivileged) //Return limited knowledge if not user or if no privilages
            {
                //Log success
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Successful Operation - Limited Access"
                );

                //Create user response
                response = new UserReponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    Description = user.Description,
                    UserRole = user.UserRole,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt
                };
            }
            else //Return full knowledge if is user or if has privilages
            {
                //Log success
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Successful Operation - Full Access"
                );

                //Create user response
                response = new UserReponseDto
                {
                    Id = user.Id,
                    Login = user.Login,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    PhoneNumber = user.PhoneNumber,
                    Description = user.Description,
                    Gender = user.Gender,
                    UserRole = user.UserRole,
                    ImageUrl = user.ImageUrl,
                    RegisteredAt = user.RegisteredAt,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt
                };

            }

            return Ok(response);
        }

        //Get user with paging and search
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserReponseDto>>> GetUsers([FromBody] GetUserDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Users.AsNoTracking();

            //Apply search based on credentials
            if(isPrivileged)
            {
                query = query.Search(dto.Query, u => u.Login, u => u.Email, u => u.DisplayName, u => u.UserRole, u => u.Description, u => u.PhoneNumber, u => u.Gender, u => u.RegisteredAt);
            }
            else
            {
                query = query.Search(dto.Query, u => u.DisplayName, u => u.UserRole, u => u.Description);
            }

            //Order by specified field if provided
            if (!string.IsNullOrEmpty(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get users with paging
            if (dto.Paging)
            {
                query = query
                    .Skip((dto.Page - 1) * dto.PageLength)
                    .Take(dto.PageLength);
            }

            List<User> users = await query.ToListAsync();

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.gotUsers", new
            {
                userIds = users.Select(u => u.Id),
                updatedBy = currentUserId
            });

            //Declare response variable
            List<UserReponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return limited knowledge if no privilages
            {
                //Log success
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "User",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.INFORMATION,
                    $"Successful Operation - Limited Access, Multiple Users"
                );

                //Create a user response list
                responses = [.. users.Select(user => new UserReponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    Description = user.Description,
                    UserRole = user.UserRole,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt
                })];
            }
            else //Return full knowledge if has privilages
            {
                //Log success
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "User",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.INFORMATION,
                    $"Successful Operation - Full Access, Multiple Users"
                );

                //Create a user response list
                responses = [.. users.Select(user => new UserReponseDto
                {
                    Id = user.Id,
                    Login = user.Login,
                    Email = user.Email,
                    PasswordHash = user.PasswordHash,
                    DisplayName = user.DisplayName,
                    PhoneNumber = user.PhoneNumber,
                    Description = user.Description,
                    Gender = user.Gender,
                    UserRole = user.UserRole,
                    ImageUrl = user.ImageUrl,
                    RegisteredAt = user.RegisteredAt,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt
                })];

            }

            //Return the users
            return Ok(responses);
        }

        //Update the selected user
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the user to delete
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Delete user
            _db.Users.Remove(user);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "User",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.deleted", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User deleted successfully!" });
        }
    }
}
