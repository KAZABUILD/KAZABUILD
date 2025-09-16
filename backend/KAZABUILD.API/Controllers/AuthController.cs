using KAZABUILD.Application.DTOs.Auth;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using IAuthorizationService = KAZABUILD.Application.Interfaces.IAuthorizationService;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers
{
    public class AuthController(KAZABUILDDBContext db, IHashingService hasher, ILoggerService logger, IRabbitMQPublisher publisher, IAuthorizationService auth, IEmailService smtp, IOptions<JwtSettings> jwtSettings, IOptions<FrontendHost> frontendHost) : Controller
    {
        private readonly KAZABUILDDBContext _db = db;
        private readonly IHashingService _hasher = hasher;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IAuthorizationService _auth = auth;
        private readonly IEmailService _smtp = smtp;
        private readonly JwtSettings _jwtSettings = jwtSettings.Value;
        private readonly string _frontendHost = frontendHost.Value.Host;

        //API endpoint that allows the user to log into the website;
        //returns the jwt token
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Declare the User variable
            User? user;

            //Get the user based on the email or login
            if (dto.Email != null)
            {
                user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            }
            else
            {
                user = await _db.Users.FirstOrDefaultAsync(u => u.Login == dto.Login);
            }

            //Return an appropriate unauthorized response if the user is not found or if the password is incorrect
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Login"
                );

                //Return proper unauthorized response
                return Unauthorized(new { message = "Invalid login!" });
            }
            else if(!_hasher.Verify(user.PasswordHash, dto.Password))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Password"
                );

                //Return proper unauthorized response
                return Unauthorized(new { message = "Invalid password!" });
            }
            else if (user.UserRole == UserRole.UNVERIFIED) //Block the login if user is unverified
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Attempted Unverified User Login"
                );

                //Return a custom unverified unauthorized response
                return Unauthorized(new { message = "Account not verified", code = "UNVERIFIED" });
            }
            else if (user.UserRole == UserRole.BANNED) //Block the login if user is banned
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Attempted Unverified User Login"
                );

                //Return a custom banned unauthorized response
                return Unauthorized(new { message = "Account banned.", code = "BANNED" });
            }

            //Generate a JWT token
            var jwt = _auth.GenerateJwtToken(user.Id, user.Email, user.UserRole);

            //Create a response with the token
            var response = new TokenResponseDto
            {
                Token = jwt
            };

            //Log the success
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - Successful Login"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.logged", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return a success response
            return Ok(response);
        }

        //API register endpoint that allows the user to create a new account
        //Sends a confirmation email to 
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
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
                    "Auth",
                    ip,
                    isUserAvailaible.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Email Or Login Already In Use"
                );

                //Return proper conflict response
                if (dto.Email == isUserAvailaible.Email)
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
                UserRole = UserRole.UNVERIFIED,
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

            //Check if the ip address exists
            if (string.IsNullOrEmpty(ip))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.ERROR,
                    "Operation Failed - IP Address Empty"
                );

                //Return conflict response
                return BadRequest(new { message = "Unable to determine the IP address" });
            }

            //Add the user to the database
            _db.Users.Add(user);

            //Create the registration token
            var token = new UserToken
            {
                UserId = user.Id,
                TokenHash = Guid.NewGuid().ToString("N"),
                TokenType = "CONFIRM_REGISTER",
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(24),
                IpAddress = ip,
                RedirectUrl = dto.RedirectUrl,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow,
            };

            //Get the redirect to frontend
            var redirectUrl = $"{_frontendHost}{dto.RedirectUrl}";
            //Create the redirect url
            var confirmUrl = $"{token.RedirectUrl}?token={token}&userId={user.Id}";
            //Create the email message body with html
            var body = $"Welcome {user.DisplayName},<br/>Click <a href=\"{confirmUrl}\">here</a> to confirm your account.";

            //Try to send the confirmation email
            try
            {
                //Send the confirmation email
                await _smtp.SendEmailAsync(user.Email, "Confirm your account", body);
            }
            catch (Exception)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { Error = "Failed to send verification email. Please try again later." });
            }

            //Add the token to the database
            _db.UserTokens.Add(token);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New User Registered"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.registered", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return a success response
            return Ok(new { message = "User registered! Please confirm via email." });
        }

        //Api confirm register endpoint
        [HttpPost("confirm-register")]
        [AllowAnonymous]
        public async Task<IActionResult> ConfirmRegister([FromBody] ConfirmRegisterDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the correct token
            var token = await _db.UserTokens.FirstOrDefaultAsync(t => t.TokenHash == dto.Token && t.TokenType == "CONFIRM_REGISTER" && t.UsedAt == null);

            //Check if the token isn't invalid or expired
            if (token == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Token"
                );

                //Return proper conflict response
                return BadRequest(new { message = "Invalid token" });
            }
            else if (token.ExpiresAt < DateTime.UtcNow)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    token.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Expired Token"
                );

                //Return proper conflict response
                return BadRequest(new { message = "Expired token" });
            }

            //Get the user the token was for
            var user = await _db.Users.FirstAsync(u => u.Id == token.UserId);

            //Update the user role and last database entry
            user.UserRole = UserRole.USER;
            user.LastEditedAt = DateTime.UtcNow;

            //Update the user in the database
            _db.Users.Update(user);

            //Update the token usage time
            token.UsedAt = DateTime.UtcNow;
            token.LastEditedAt = DateTime.UtcNow;

            //Update the user in the database
            _db.UserTokens.Update(token);

            //Commit the changes to the database
            await _db.SaveChangesAsync();

            //Log the confirmation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - User Registration confirmed"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.registrationConfirmed", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return a success response
            return Ok(new { message = "Registration confirmed! You can now log in." });
        }

        //API endpoint for reseting the password,
        //sends an email for resetting the password
        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the user with email
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);

            //Check if the user exists
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such User For Password Reset"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Check if the ip address exists
            if (string.IsNullOrEmpty(ip))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.ERROR,
                    "Operation Failed - IP Address Empty For Password Reset"
                );

                //Return conflict response
                return BadRequest(new { message = "Unable to determine the IP address" });
            }

            var token = new UserToken
            {
                UserId = user.Id,
                TokenHash = Guid.NewGuid().ToString("N"),
                TokenType = "RESET_PASSWORD",
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(2),
                RedirectUrl = dto.RedirectUrl,
                IpAddress = ip,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Get the redirect to frontend
            var redirectUrl = $"{_frontendHost}{dto.RedirectUrl}";
            //Create the redirect url
            var confirmUrl = $"{token.RedirectUrl}?token={token}&userId={user.Id}";
            //Create the email message body with html
            var body = $"Welcome {user.DisplayName},<br/>Click <a href=\"{confirmUrl}\">here</a> to reset your password.";

            //Try to send the confirmation email
            try
            {
                //Send the confirmation email
                await _smtp.SendEmailAsync(user.Email, "Confirm password reset", body);
            }
            catch (Exception)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { Error = "Failed to send verification email. Please try again later." });
            }

            //Add the token to the database
            _db.UserTokens.Add(token);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - Reset Password Email Sent"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.passwordResetSend", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return a success response
            return Ok(new { message = "Password reset instructions sent!" });
        }

        //API endpoint for conforming the password reset,
        //Redirects to a password reset frontend url
        [HttpPost("confirm-reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ConfirmResetPassword([FromBody] ConfirmPasswordResetDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the correct token
            var token = await _db.UserTokens.FirstOrDefaultAsync(t => t.TokenHash == dto.Token && t.TokenType == "RESET_PASSWORD" && t.UsedAt == null);

            //Check if the token isn't invalid or expired
            if (token == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Token"
                );

                //Return proper conflict response
                return BadRequest(new { message = "Invalid token" });
            }
            else if (token.ExpiresAt < DateTime.UtcNow)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    token.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Expired Token"
                );

                //Return proper conflict response
                return BadRequest(new { message = "Expired token" });
            }

            //Get the user the token was for
            var user = await _db.Users.FirstAsync(u => u.Id == token.UserId);

            //Update the password
            user.PasswordHash = _hasher.Hash(dto.NewPassword);
            user.LastEditedAt = DateTime.UtcNow;

            //Update the user in the database
            _db.Users.Update(user);

            //Update the token usage time 
            token.UsedAt = DateTime.UtcNow;
            token.LastEditedAt = DateTime.UtcNow;

            //Update the user in the database
            _db.UserTokens.Update(token);

            //Commit the changes to the database
            await _db.SaveChangesAsync();

            //Log the confirmation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - User Registration confirmed"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.passwordResetConfirmed", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Return a success response
            return Ok(new { message = "Password reset successfully!" });
        }
    }
}
