using Google.Apis.Auth;
using KAZABUILD.Application.DTOs.Auth;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using IAuthorizationService = KAZABUILD.Application.Interfaces.IAuthorizationService;

namespace KAZABUILD.API.Controllers
{
    //Controller for Auth related endpoints
    [ApiController]
    [Route("[controller]")]
    public class AuthController(KAZABUILDDBContext db, IHashingService hasher, ILoggerService logger, IRabbitMQPublisher publisher, IAuthorizationService auth, IEmailService smtp, IOptions<FrontendSettings> frontend, IOptions<BackendHost> backendHost) : Controller
    {
        private readonly KAZABUILDDBContext _db = db;
        private readonly IHashingService _hasher = hasher;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IAuthorizationService _auth = auth;
        private readonly IEmailService _smtp = smtp;
        private readonly FrontendSettings _frontend = frontend.Value;
        private readonly string _backendHost = backendHost.Value.Host;

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
            else if (dto.Login != null)
            {
                user = await _db.Users.FirstOrDefaultAsync(u => u.Login == dto.Login);
            }
            else
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Missing Email And Login"
                );

                //Return proper unauthorized response
                return BadRequest(new { message = "Provide either an email or login!" });
            }

            //Return an appropriate unauthorized response if the user is not found or if the password is incorrect
            if (user == null || user.PasswordHash == null)
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
            else if (!_hasher.Verify(dto.Password, user.PasswordHash))
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
                    "Operation Failed - Attempted Banned User Login"
                );

                //Return a custom banned unauthorized response
                return Unauthorized(new { message = "Account banned.", code = "BANNED" });
            }

            //Check if the user has double factor authentication enabled
            if (user.EnableDoubleFactorAuthentication)
            {
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
                        "Operation Failed - IP Address Empty for login"
                    );

                    //Return conflict response
                    return BadRequest(new { message = "Unable to determine the IP address" });
                }

                //Generate an authentication token
                var token = new UserToken
                {
                    UserId = user.Id,
                    Token = Guid.NewGuid().ToString("N").Substring(0, 6),
                    TokenType = TokenType.LOGIN_2FA,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = DateTime.UtcNow.AddMinutes(10),
                    IpAddress = ip,
                    DatabaseEntryAt = DateTime.UtcNow,
                    LastEditedAt = DateTime.UtcNow,
                };

                //Create the email message body with html
                var body = EmailBodyHelper.GetTwoFactorEmailBody(user.DisplayName, token.Token);

                //Try to send the confirmation email
                try
                {
                    //Send the confirmation email
                    await _smtp.SendEmailAsync(user.Email, "KAZABUILD login verification code", body);
                }
                catch (Exception)
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new { Error = "Failed to send verification email. Please try again later." });
                }

                //Add the token to the database
                _db.UserTokens.Add(token);

                //Save changes to the database
                await _db.SaveChangesAsync();

                //Log the success
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.INFORMATION,
                    "Successful Operation - 2FA email sent!"
                );

                //Publish RabbitMQ event
                await _publisher.PublishAsync("auth.2fa", new
                {
                    userId = user.Id,
                    updatedBy = currentUserId
                });

                //Return a success response with 
                return Ok(new { code = "2FA_REQUIRED", userId = user.Id });
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

        [HttpPost("verify-2fa")]
        [AllowAnonymous]
        public async Task<IActionResult> Verify2Fa([FromBody] Verify2FactorAuthenticationDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the correct token
            var token = await _db.UserTokens.FirstOrDefaultAsync(t => t.UserId == currentUserId && t.Token == dto.Token && t.TokenType == TokenType.LOGIN_2FA && t.UsedAt == null);

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
                    "Operation Failed - Invalid 2fa Token"
                );

                //Return a proper conflict response
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
                    "Operation Failed - Expired 2fa Token"
                );

                //Return a proper conflict response
                return BadRequest(new { message = "Expired token" });
            }

            //Get the user the token was for
            var user = await _db.Users.FirstAsync(u => u.Id == token.UserId);

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
                "Successful Operation - User Login 2 Factor Authenticated"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.loginAuthenticated", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Generate a JWT token
            var jwt = _auth.GenerateJwtToken(user.Id, user.Email, user.UserRole);

            //Create a response with the token
            var response = new TokenResponseDto
            {
                Token = jwt
            };

            //Return a success response
            return Ok(response);
        }

        [HttpPost("google-login")]
        [AllowAnonymous]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Connect to google and get the user info
            var payload = await GoogleJsonWebSignature.ValidateAsync(dto.IdToken);

            //Check if the payload was received
            if (payload == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Google Login Token"
                );

                //Return an anauthorized response
                return Unauthorized(new { message = "Invalid Google token." });
            }

            //Get the google authenticated user
            var user = await _db.Users.FirstOrDefaultAsync(u => u.GoogleId == payload.Subject || u.Email == payload.Email);

            //Check if the user exists
            if (user == null)
            {
                //Create a new user
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = payload.Email,
                    DisplayName = payload.Name,
                    Login = payload.Email,
                    GoogleId = payload.Subject,
                    GoogleProfilePicture = payload.Picture,
                    RegisteredAt = DateTime.UtcNow,
                    Gender = "Unknown",
                    UserRole = UserRole.USER,
                    ReceiveEmailNotifications = true,
                    DatabaseEntryAt = DateTime.UtcNow,
                    LastEditedAt = DateTime.UtcNow
                };

                //Add the user to the database
                _db.Users.Add(user);

                //Save changes to the database
                await _db.SaveChangesAsync();

                //Log the confirmation
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Auth",
                    ip,
                    user.Id,
                    PrivacyLevel.INFORMATION,
                    "Successful Operation - User Registered With Google"
                );

                //Publish RabbitMQ event
                await _publisher.PublishAsync("auth.registeredGoogle", new
                {
                    userId = user.Id,
                    updatedBy = currentUserId
                });
            }

            //Log the confirmation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Auth",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - User Login With Google"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("auth.loggedGoogle", new
            {
                userId = user.Id,
                updatedBy = currentUserId
            });

            //Generate a JWT token
            var jwt = _auth.GenerateJwtToken(user.Id, user.Email, user.UserRole);

            //Create a response with the token
            var response = new TokenResponseDto
            {
                Token = jwt
            };

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
                Token = Guid.NewGuid().ToString("N"),
                TokenType = TokenType.CONFIRM_REGISTER,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(24),
                IpAddress = ip,
                RedirectUrl = dto.RedirectUrl,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow,
            };

            //Create the confirmation backend call link
            var confirmUrl = $"{_backendHost}/auth/confirm-register?token={token.Token}&userId={user.Id}";
            //Create the email message body with html
            var body = EmailBodyHelper.GetAccountConfirmationEmailBody(user.DisplayName, confirmUrl);

            //Try to send the confirmation email
            try
            {
                //Send the confirmation email
                await _smtp.SendEmailAsync(user.Email, "Confirm your KAZABUILD account", body);
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
            var token = await _db.UserTokens.FirstOrDefaultAsync(t => t.Token == dto.Token && t.TokenType == TokenType.CONFIRM_REGISTER && t.UsedAt == null);

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
                return Redirect($"{_frontend.Host}{_frontend.ErrorPage}/?error=InvalidToken");
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
                return Redirect($"{_frontend.Host}{_frontend.ErrorPage}/?error=ExpiredToken");
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
            return Redirect($"{_frontend.Host}{token.RedirectUrl}?token={token}&userId={user.Id}");
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
                Token = Guid.NewGuid().ToString("N"),
                TokenType = TokenType.RESET_PASSWORD,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(2),
                RedirectUrl = dto.RedirectUrl,
                IpAddress = ip,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Create the confirmation backend call link
            var confirmUrl = $"{_backendHost}/auth/confirm-reset-password?token={token.Token}&userId={user.Id}";

            //Create the email message body with html
            var body = EmailBodyHelper.GetPasswordResetEmailBody(user.DisplayName, confirmUrl);

            //Try to send the confirmation email
            try
            {
                //Send the confirmation email
                await _smtp.SendEmailAsync(user.Email, "Confirm password reset for your KAZABUILD account", body);
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
            var token = await _db.UserTokens.FirstOrDefaultAsync(t => t.Token == dto.Token && t.TokenType == TokenType.RESET_PASSWORD && t.UsedAt == null);

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
                return Redirect($"{_frontend.Host}{_frontend.ErrorPage}/?error=InvalidToken");
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
                return Redirect($"{_frontend.Host}{_frontend.ErrorPage}/?error=ExpiredToken");
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
            return Redirect($"{_frontend.Host}{token.RedirectUrl}?token={token}&userId={user.Id}");
        }
    }
}
