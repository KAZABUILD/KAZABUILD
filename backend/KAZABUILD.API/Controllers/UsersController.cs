using KAZABUILD.Application.DTOs.User;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers
{
    //Controller for user related endpoints
    [ApiController]
    [Route("[controller]")]
    // [EnableRateLimiting("Fixed")] <- Uncomment to add rate limiting
    public class UsersController(KAZABUILDDBContext db, ILoggerService logger, IHashingService hasher, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IHashingService _hasher = hasher;
        private readonly IRabbitMQPublisher _publisher = publisher;

        //API Endpont for creating a new user
        [HttpPost("Add")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> AddUser([FromBody] CreateUserDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the email is not already in use
            var isUserAvailaible = await _db.Users.FirstOrDefaultAsync(u => u.Login == dto.Login || u.Email == dto.Email);
            if (isUserAvailaible != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "User",
                    ip,
                    isUserAvailaible.Id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - Email Already In Use"
                );

                //Return proper conflict response
                if(dto.Email == isUserAvailaible.Email)
                    return Conflict(new { message = "Email Already In Use" });
                else
                    return Conflict(new { message = "Login Already In Use" });
            }
            

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
                Birth = dto.Birth,
                RegisteredAt = dto.RegisteredAt,
                Address = dto.Address,
                ProfileAccessibility = dto.ProfileAccessibility,
                Theme = dto.Theme,
                Language = dto.Language,
                Location = dto.Location,
                ReceiveEmailNotifications = dto.ReceiveEmailNotifications,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the user to the database
            _db.Users.Add(user);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
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

        //API endpoint for updating the selected user
        //Users can only update their own profiles and settings
        //Admins can update all information
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

                //Return forbidden response
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
                changedFields.Add("DisplayName: " + user.DisplayName);

                user.DisplayName = dto.DisplayName;
            }
            if (dto.PhoneNumber != null)
            {
                changedFields.Add("PhoneNumber: " + user.PhoneNumber);

                user.PhoneNumber = dto.PhoneNumber;
            }
            if (dto.Description != null)
            {
                changedFields.Add("Description: " + user.Description);

                user.Description = dto.Description;
            }
            if (!string.IsNullOrEmpty(dto.Gender))
            {
                changedFields.Add("Gender: " + user.Gender);

                user.Gender = dto.Gender;
            }
            if (!string.IsNullOrEmpty(dto.ImageUrl))
            {
                changedFields.Add("ImageUrl: " + user.ImageUrl);

                user.ImageUrl = dto.ImageUrl;
            }
            if (dto.Birth != null)
            {
                changedFields.Add("Birth: " + user.Birth);

                user.Birth = (DateTime)dto.Birth;
            }
            if (dto.Address != null)
            {
                if(user.Address == null)
                {
                    changedFields.Add("Added Address");

                    user.Address = dto.Address;
                }
                else
                {
                    if (dto.Address.Country != null)
                    {
                        user.Address.Country = dto.Address.Country;

                        changedFields.Add("Country: " + user.Address.Country);
                    }
                    if (dto.Address.Province != null)
                    {
                        user.Address.Province = dto.Address.Province;

                        changedFields.Add("Province: " + user.Address.Province);
                    }
                    if (dto.Address.City != null)
                    {
                        user.Address.City = dto.Address.City;

                        changedFields.Add("City: " + user.Address.City);
                    }
                    if (dto.Address.Street != null)
                    {
                        user.Address.Street = dto.Address.Street;

                        changedFields.Add("Street: " + user.Address.Street);
                    }
                    if (dto.Address.StreetNumber != null)
                    {
                        user.Address.StreetNumber = dto.Address.StreetNumber;

                        changedFields.Add("StreetNumber: " + user.Address.StreetNumber);
                    }
                    if (dto.Address.PostalCode != null)
                    {
                        user.Address.PostalCode = dto.Address.PostalCode;

                        changedFields.Add("PostalCode: " + user.Address.PostalCode);
                    }
                    if (dto.Address.ApartmentNumber != null)
                    {
                        changedFields.Add("ApartmentNumber: " + user.Address.ApartmentNumber);

                        user.Address.ApartmentNumber = dto.Address.ApartmentNumber;
                    }
                }
            }
            if (dto.ProfileAccessibility != null)
            {
                user.ProfileAccessibility = (ProfileAccessibility)dto.ProfileAccessibility;

                changedFields.Add("ProfileAccessibility: " + user.ProfileAccessibility);
            }
            if (dto.Theme != null)
            {
                changedFields.Add("Theme: " + user.Theme);

                user.Theme = (Theme)dto.Theme;
            }
            if (dto.Language != null)
            {
                changedFields.Add("Language: " + user.Language);

                user.Language = (Language)dto.Language;
            }
            if (!string.IsNullOrEmpty(dto.Location))
            {
                changedFields.Add("Location: " + user.Location);

                user.Location = dto.Location;
            }

            //Update allowed fields - administration
            if (isPrivileged)
            {
                if (!string.IsNullOrEmpty(dto.Email))
                {
                    changedFields.Add("Email: " + user.Email);

                    user.Email = dto.Email;
                }
                if (!string.IsNullOrEmpty(dto.Login))
                {
                    changedFields.Add("Login: " + user.Login);

                    user.Login = dto.Login;
                }
                if (dto.UserRole != null)
                {
                    changedFields.Add("UserRole: " + user.UserRole);

                    user.UserRole = (UserRole)dto.UserRole;
                }
                if (!string.IsNullOrEmpty(dto.Note))
                {
                    changedFields.Add("Note: " + user.Note);

                    user.Note = dto.Note;
                }
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

        //API endpoint for changing the password, users can change their own password
        [HttpPost("{id:guid}/change-password")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> ChangePassword(Guid id, [FromBody] ChangePasswordDto dto)
        {
            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get user id and check if the calling user matches the changing user
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            if (id != currentUserId)
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

                //Return forbidden response
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

            //Verify if the old password is correct
            if (!_hasher.Verify(user.PasswordHash, dto.OldPassword))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "UPDATE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - Invalid Password"
                );

                //Return bad request response
                return BadRequest(new { message = "Old password incorrect!" });
            }

            //Change the password
            user.PasswordHash = _hasher.Hash(dto.NewPassword);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Return success response
            return Ok(new { message = "Password changed successfully!" });
        }

        //API endpoint for getting the user specified by id,
        //different level of information returned based on privilages
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

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserReponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check if the calling user is followed
            var isFollowed = await _db.UserFollows.AnyAsync(f => f.FollowerId == id && f.FollowedId == currentUserId);

            //Check what permissions user has and return respective information
            if(!isSelf && !isPrivileged
                && (user.ProfileAccessibility == ProfileAccessibility.PRIVATE
                || (user.ProfileAccessibility == ProfileAccessibility.FOLLOWS && !isFollowed))) //Return restricted knowledge if the user set their profile to private or restricted access
            {
                //Change log description
                logDescription = "Successful Operation - Protected Access";

                //Create user response
                response = new UserReponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    UserRole = user.UserRole
                };
            }
            if (!isSelf && !isPrivileged) //Return limited knowledge if not user or if no privilages
            {
                //Change log description
                logDescription = "Successful Operation - Limited Access";

                //Create user response
                response = new UserReponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    Description = user.Description,
                    ImageUrl = user.ImageUrl,
                    UserRole = user.UserRole
                };
            }
            else //Return full knowledge if is user or if has privilages
            {
                //Change log description
                logDescription = "Successful Operation - Full Access";

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
                    Birth = user.Birth,
                    Address = user.Address,
                    ProfileAccessibility = user.ProfileAccessibility,
                    Theme = user.Theme,
                    Language = user.Language,
                    Location = user.Location,
                    ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt,
                    Note = user.Note
                };

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "User",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.got", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            return Ok(response);
        }

        //API endpoint for getting users with pagination and search,
        //different level of information returned based on privilages
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
                query = query.Search(dto.Query, u => u.Login, u => u.Email, u => u.DisplayName, u => u.UserRole, u => u.Description, u => u.PhoneNumber, u => u.Gender, u => u.RegisteredAt, u => u.Birth, u => u.Language, u => u.Location, u => u.Note);
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

            //Log Description string declaration
            string logDescription;

            List<User> users = await query.ToListAsync();

            //Declare response variable
            List<UserReponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return limited knowledge if no privilages
            {
                //Change log description
                logDescription = "Successful Operation - Limited Access, Multiple Users";

                //Get all follows for the current user
                var followers = await _db.UserFollows
                    .Where(f => f.FollowedId == currentUserId)
                    .Select(f => f.FollowerId)
                    .ToListAsync();

                //Create a user response list
                responses = [.. users.Select(user =>
                {
                    //Check if the calling user is followed
                    var isFollowed = followers.Contains(user.Id);

                    //Check if current user is getting themselves
                    var isSelf = currentUserId == user.Id;

                    //Return limited or restricted information based on user profile settings
                    if(!isSelf && user.ProfileAccessibility == ProfileAccessibility.PRIVATE || (user.ProfileAccessibility == ProfileAccessibility.FOLLOWS && !isFollowed))
                    {
                        //Return restricted knowledge if the user set their profile to private or restricted access
                        return new UserReponseDto
                        {
                            Id = user.Id,
                            DisplayName = user.DisplayName,
                            UserRole = user.UserRole
                        };
                    }
                    else if(!isSelf)
                    {
                        //Return limited knowledge if not user
                        return new UserReponseDto
                        {
                            Id = user.Id,
                            DisplayName = user.DisplayName,
                            Description = user.Description,
                            ImageUrl = user.ImageUrl,
                            UserRole = user.UserRole
                        };
                    }
                    else
                    {
                        //Return full knowledge if is user
                        return new UserReponseDto
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
                            Birth = user.Birth,
                            Address = user.Address,
                            ProfileAccessibility = user.ProfileAccessibility,
                            Theme = user.Theme,
                            Language = user.Language,
                            Location = user.Location,
                            ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                            DatabaseEntryAt = user.DatabaseEntryAt,
                            LastEditedAt = user.LastEditedAt,
                            Note = user.Note
                        };
                    }
                })];
            }
            else //Return full knowledge if has privilages
            {
                //Change log description
                logDescription = "Successful Operation - Full Access, Multiple Users";

                //Create a user response list
                responses = [.. users.Select(user => new UserReponseDto
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
                    Birth = user.Birth,
                    Address = user.Address,
                    ProfileAccessibility = user.ProfileAccessibility,
                    Theme = user.Theme,
                    Language = user.Language,
                    Location = user.Location,
                    ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                    DatabaseEntryAt = user.DatabaseEntryAt,
                    LastEditedAt = user.LastEditedAt,
                    Note = user.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "User",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.gotUsers", new
            {
                userIds = users.Select(u => u.Id),
                updatedBy = currentUserId
            });

            //Return the users
            return Ok(responses);
        }

        //API endpoint for deleting the selected user for administration
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

            //Hamdle deleting followed user and followers to avoid conflicts with cascade deletes
            //Get all followers' and followed users' follows
            var follows = _db.UserFollows.Where(f => f.FollowedId == user.Id || f.FollowerId == user.Id);

            //Remove all user follows containing the user id of the user to be deleted
            _db.UserFollows.RemoveRange(follows);

            //Delete the user
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
