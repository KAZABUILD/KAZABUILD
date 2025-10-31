using KAZABUILD.Application.DTOs.Users.User;
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
    /// Controller for User related endpoints.
    /// Controls both user account information and user settings.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="hasher"></param>
    /// <param name="publisher"></param>
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

        /// <summary>
        /// API Endpoint for creating a new user for staff.
        /// Regular users should use auth endpoints instead.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> AddUser([FromBody] CreateUserDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the email is not already in use
            var isUserAvailable = await _db.Users.FirstOrDefaultAsync(u => u.Login == dto.Login || u.Email == dto.Email);
            if (isUserAvailable != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "User",
                    ip,
                    isUserAvailable.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Email Already In Use"
                );

                //Return proper conflict response
                if (dto.Email == isUserAvailable.Email)
                    return Conflict(new { message = "Email already in use" });
                else
                    return Conflict(new { message = "Login already in use" });
            }

            //Check if the user has sufficient permissions
            if (currentUserRole <= dto.UserRole)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "User",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Email Already In Use"
                );

                //Return forbidden response
                return Forbid();
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
                ImageId = dto.ImageId,
                Birth = dto.Birth,
                RegisteredAt = dto.RegisteredAt,
                Address = dto.Address,
                ProfileAccessibility = dto.ProfileAccessibility,
                Theme = dto.Theme,
                Language = dto.Language,
                Location = dto.Location,
                ReceiveEmailNotifications = dto.ReceiveEmailNotifications,
                EnableDoubleFactorAuthentication = dto.EnableDoubleFactorAuthentication,
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
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User created successfully!", id = user.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected user.
        /// Users can only update their own profiles and settings.
        /// Admins can update all information.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user is editing themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

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

            //Get the user to edit
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.DisplayName))
            {
                changedFields.Add("DisplayName: " + user.DisplayName);

                user.DisplayName = dto.DisplayName;
            }
            if (dto.PhoneNumber != null)
            {
                changedFields.Add("PhoneNumber: " + user.PhoneNumber);

                if (string.IsNullOrWhiteSpace(dto.PhoneNumber))
                    user.PhoneNumber = null;
                else
                    user.PhoneNumber = dto.PhoneNumber;
            }
            if (dto.Description != null)
            {
                changedFields.Add("Description: " + user.Description);

                if (string.IsNullOrWhiteSpace(dto.Description))
                    user.Description = null;
                else
                    user.Description = dto.Description;
            }
            if (!string.IsNullOrWhiteSpace(dto.Gender))
            {
                changedFields.Add("Gender: " + user.Gender);

                user.Gender = dto.Gender;
            }
            if (dto.ImageId != null)
            {
                changedFields.Add("ImageId: " + user.ImageId);

                user.ImageId = dto.ImageId;
            }
            if (dto.Birth != null)
            {
                changedFields.Add("Birth: " + user.Birth);

                user.Birth = (DateTime)dto.Birth;
            }
            if (dto.Address != null)
            {
                if (user.Address == null)
                {
                    changedFields.Add("Added Address");

                    user.Address = dto.Address;
                }
                else
                {
                    if (dto.Address.Country != null)
                    {
                        changedFields.Add("Country: " + user.Address.Country);

                        user.Address.Country = dto.Address.Country;
                    }
                    if (dto.Address.Province != null)
                    {
                        changedFields.Add("Province: " + user.Address.Province);

                        if (string.IsNullOrWhiteSpace(dto.Address.Province))
                            user.Address.Province = null;
                        else
                            user.Address.Province = dto.Address.Province;
                    }
                    if (dto.Address.City != null)
                    {
                        changedFields.Add("City: " + user.Address.City);

                        user.Address.City = dto.Address.City;
                    }
                    if (dto.Address.Street != null)
                    {
                        changedFields.Add("Street: " + user.Address.Street);

                        user.Address.Street = dto.Address.Street;
                    }
                    if (dto.Address.StreetNumber != null)
                    {
                        changedFields.Add("StreetNumber: " + user.Address.StreetNumber);

                        user.Address.StreetNumber = dto.Address.StreetNumber;
                    }
                    if (dto.Address.PostalCode != null)
                    {
                        changedFields.Add("PostalCode: " + user.Address.PostalCode);

                        user.Address.PostalCode = dto.Address.PostalCode;
                    }
                    if (dto.Address.ApartmentNumber != null)
                    {
                        changedFields.Add("ApartmentNumber: " + user.Address.ApartmentNumber);

                        if (string.IsNullOrWhiteSpace(dto.Address.ApartmentNumber))
                            user.Address.ApartmentNumber = null;
                        else
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
            if (!string.IsNullOrWhiteSpace(dto.Location))
            {
                changedFields.Add("Location: " + user.Location);

                user.Location = dto.Location;
            }
            if (dto.ReceiveEmailNotifications != null)
            {
                changedFields.Add("ReceiveEmailNotifications: " + user.ReceiveEmailNotifications);

                user.ReceiveEmailNotifications = (bool)dto.ReceiveEmailNotifications;
            }
            if (dto.EnableDoubleFactorAuthentication != null)
            {
                changedFields.Add("EnableDoubleFactorAuthentication : " + user.EnableDoubleFactorAuthentication);

                user.EnableDoubleFactorAuthentication = (bool)dto.EnableDoubleFactorAuthentication;
            }

            //Update allowed fields - administration
            if (isPrivileged)
            {
                if (!string.IsNullOrWhiteSpace(dto.Email))
                {
                    changedFields.Add("Email: " + user.Email);

                    user.Email = dto.Email;
                }
                if (!string.IsNullOrWhiteSpace(dto.Login))
                {
                    changedFields.Add("Login: " + user.Login);

                    user.Login = dto.Login;
                }
                if (dto.BannedUntil != null)
                {
                    if (dto.BannedUntil == DateTime.MinValue)
                        user.BannedUntil = null;
                    else
                        user.BannedUntil = dto.BannedUntil;
                }
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + user.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        user.Note = null;
                    else
                        user.Note = dto.Note;
                }
                //Hash password if provided
                if (!string.IsNullOrWhiteSpace(dto.Password))
                {
                    user.PasswordHash = _hasher.Hash(dto.Password);

                    changedFields.Add("Changed Password");
                }
            }

            //Update role based on user privilege
            if (dto.UserRole != null && dto.UserRole < currentUserRole)
            {
                changedFields.Add("UserRole: " + user.UserRole);

                user.UserRole = (UserRole)dto.UserRole;
            }

            //Update edit timestamp
            user.LastEditedAt = DateTime.UtcNow;

            //Update the user
            _db.Users.Update(user);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
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

        /// <summary>
        /// API endpoint for changing passwords, users can only change their own password.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:guid}/change-password")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> ChangePassword(Guid id, [FromBody] ChangePasswordDto dto)
        {
            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get user id and check if the calling user matches the changing user
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            if (id != currentUserId)
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

            //Get the user to edit
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null || user.PasswordHash == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Verify if the old password is correct
            if (!_hasher.Verify(dto.OldPassword, user.PasswordHash))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Password"
                );

                //Return bad request response
                return BadRequest(new { message = "Old password incorrect!" });
            }

            //Change the password
            user.PasswordHash = _hasher.Hash(dto.NewPassword);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "User",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - Changed Password"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.passwordUpdated", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Password changed successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the user specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserResponseDto>> GetUser(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
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
            UserResponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check if the calling user is followed
            var isFollowed = await _db.UserFollows.AnyAsync(f => f.FollowerId == id && f.FollowedId == currentUserId);

            //Check what permissions user has and return respective information
            if (!isSelf && !isPrivileged
                && (user.ProfileAccessibility == ProfileAccessibility.PRIVATE
                || user.ProfileAccessibility == ProfileAccessibility.FOLLOWS && !isFollowed)) //Return restricted knowledge if the user set their profile to private or restricted access
            {
                //Change log description
                logDescription = "Successful Operation - Protected Access";

                //Create user response
                response = new UserResponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    UserRole = user.UserRole
                };
            }
            else if (!isSelf && !isPrivileged) //Return limited knowledge if not user or if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - Limited Access";

                //Create user response
                response = new UserResponseDto
                {
                    Id = user.Id,
                    DisplayName = user.DisplayName,
                    Description = user.Description,
                    ImageId = user.ImageId,
                    UserRole = user.UserRole
                };
            }
            else if (isSelf && !isPrivileged) //Return full knowledge if is user
            {
                //Change log description
                logDescription = "Successful Operation - Full Access";

                //Create user response
                response = new UserResponseDto
                {
                    Id = user.Id,
                    Login = user.Login,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    PhoneNumber = user.PhoneNumber,
                    Description = user.Description,
                    Gender = user.Gender,
                    UserRole = user.UserRole,
                    ImageId = user.ImageId,
                    RegisteredAt = user.RegisteredAt,
                    Birth = user.Birth,
                    Address = user.Address,
                    ProfileAccessibility = user.ProfileAccessibility,
                    Theme = user.Theme,
                    Language = user.Language,
                    Location = user.Location,
                    ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                    EnableDoubleFactorAuthentication = user.EnableDoubleFactorAuthentication
                };
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create user response
                response = new UserResponseDto
                {
                    Id = user.Id,
                    Login = user.Login,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    PhoneNumber = user.PhoneNumber,
                    Description = user.Description,
                    Gender = user.Gender,
                    UserRole = user.UserRole,
                    ImageId = user.ImageId,
                    RegisteredAt = user.RegisteredAt,
                    Birth = user.Birth,
                    Address = user.Address,
                    ProfileAccessibility = user.ProfileAccessibility,
                    Theme = user.Theme,
                    Language = user.Language,
                    Location = user.Location,
                    ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                    EnableDoubleFactorAuthentication = user.EnableDoubleFactorAuthentication,
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
                gotBy = currentUserId
            });

            //Return the user
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting users with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserResponseDto>>> GetUsers([FromBody] GetUserDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Users.AsNoTracking();

            //Filter by the variables if included in request
            if (dto.Gender != null)
            {
                query = query.Where(u => dto.Gender.Contains(u.Gender));
            }
            if (dto.UserRole != null)
            {
                query = query.Where(u => dto.UserRole.Contains(u.UserRole));
            }

            //Apply search based on provided query string if query string included in request
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                //Apply the query based on user privilege
                if (isPrivileged)
                {
                    query = query.Search(dto.Query, u => u.Login, u => u.Email, u => u.DisplayName, u => u.UserRole, u => u.Description!,
                        u => u.PhoneNumber!, u => u.Gender, u => u.RegisteredAt, u => u.Birth!, u => u.Language, u => u.Location!, u => u.Note!);
                }
                else
                {
                    query = query.Search(dto.Query, u => u.DisplayName, u => u.UserRole, u => u.Description!);
                }
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get users with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            //Get all users
            List<User> users = await query.ToListAsync();

            //Declare response variable
            List<UserResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return limited knowledge if no privileges
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
                    if(!isSelf && (user.ProfileAccessibility == ProfileAccessibility.PRIVATE || user.ProfileAccessibility == ProfileAccessibility.FOLLOWS && !isFollowed))
                    {
                        //Return restricted knowledge if the user set their profile to private or restricted access
                        return new UserResponseDto
                        {
                            Id = user.Id,
                            DisplayName = user.DisplayName,
                            UserRole = user.UserRole
                        };
                    }
                    else if(!isSelf)
                    {
                        //Return limited knowledge if not user
                        return new UserResponseDto
                        {
                            Id = user.Id,
                            DisplayName = user.DisplayName,
                            Description = user.Description,
                            ImageId = user.ImageId,
                            UserRole = user.UserRole
                        };
                    }
                    else
                    {
                        //Return full knowledge if is user
                        return new UserResponseDto
                        {
                            Id = user.Id,
                            Login = user.Login,
                            Email = user.Email,
                            DisplayName = user.DisplayName,
                            PhoneNumber = user.PhoneNumber,
                            Description = user.Description,
                            Gender = user.Gender,
                            UserRole = user.UserRole,
                            ImageId = user.ImageId,
                            RegisteredAt = user.RegisteredAt,
                            Birth = user.Birth,
                            Address = user.Address,
                            ProfileAccessibility = user.ProfileAccessibility,
                            Theme = user.Theme,
                            Language = user.Language,
                            Location = user.Location,
                            ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                            EnableDoubleFactorAuthentication = user.EnableDoubleFactorAuthentication,
                            DatabaseEntryAt = user.DatabaseEntryAt,
                            LastEditedAt = user.LastEditedAt,
                            Note = user.Note
                        };
                    }
                })];
            }
            else //Return full knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Full Access, Multiple Users";

                //Create a user response list
                responses = [.. users.Select(user => new UserResponseDto
                {
                    Id = user.Id,
                    Login = user.Login,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    PhoneNumber = user.PhoneNumber,
                    Description = user.Description,
                    Gender = user.Gender,
                    UserRole = user.UserRole,
                    ImageId = user.ImageId,
                    RegisteredAt = user.RegisteredAt,
                    Birth = user.Birth,
                    Address = user.Address,
                    ProfileAccessibility = user.ProfileAccessibility,
                    Theme = user.Theme,
                    Language = user.Language,
                    Location = user.Location,
                    ReceiveEmailNotifications = user.ReceiveEmailNotifications,
                    EnableDoubleFactorAuthentication = user.EnableDoubleFactorAuthentication,
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
                gotBy = currentUserId
            });

            //Return the users
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected user for staff.
        /// Removes all related UserFollows as well.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the user to delete
            var user = await _db.Users.Include(u => u.Images).FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such User"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Check if the user has sufficient permissions
            if (currentUserRole <= user.UserRole)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "User",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Email Already In Use"
                );

                //Return forbidden response
                return Forbid();
            }

            //Remove all related images
            if (user.Images.Count != 0)
            {
                foreach (var image in user.Images)
                {
                    //Remove the file from the file system
                    if (System.IO.File.Exists(image.Location))
                        System.IO.File.Delete(image.Location);
                }

                //Delete all related images
                _db.Images.RemoveRange(user.Images);
            }

            //Handle deleting followed user and followers to avoid conflicts with cascade deletes
            //Get all followers' and followed users' follows
            var follows = await _db.UserFollows.Where(f => f.FollowedId == user.Id || f.FollowerId == user.Id).ToListAsync();

            //Remove all user follows containing the user id of the user to be deleted
            if (follows.Count != 0)
            {
                _db.UserFollows.RemoveRange(follows);
            }

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
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User deleted successfully!" });
        }
    }
}
