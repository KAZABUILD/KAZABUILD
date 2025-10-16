using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AdminController(KAZABUILDDBContext db, IHashingService hasher, ILoggerService logger, IRabbitMQPublisher publisher, IDataSeeder seeder, IOptions<SystemAdminSetings> systemAdminSettigns, IOptions<SmtpSettings> SmtpServiceSettings) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly IHashingService _hasher = hasher;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IDataSeeder _seeder = seeder;
        private readonly SystemAdminSetings _systemAdminSettigns = systemAdminSettigns.Value;
        private readonly SmtpSettings _smtpServiceSettings = SmtpServiceSettings.Value;

        /// <summary>
        /// Allows the super admins to reset the system admin account in case of data breach.
        /// </summary>
        /// <returns></returns>
        [HttpPost("reset")]
        [Authorize(Policy = "SuperAdmins")]
        public async Task<IActionResult> ResetSystemAdmin()
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Declare the reserved system admin id
            Guid id = Guid.Parse("00000000-0000-0000-0000-000000000001");

            //Check if the system admin exists
            var systemUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (systemUser != null)
            {
                //Remove the system admin from the database
                _db.Users.Remove(systemUser);

                //Save changes to the database
                await _db.SaveChangesAsync();

                //Log deletion of the system admin
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Admin",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Deleted The Old System Admin"
                );
            }

            //Create a new system admin to add
            systemUser = new User
            {
                Id = id,
                Login = _systemAdminSettigns.Login,
                Email = _smtpServiceSettings.Username,
                PasswordHash = _hasher.Hash(_systemAdminSettigns.Password),
                DisplayName = _systemAdminSettigns.Login,
                Description = "System Admin account. Beware!",
                Gender = "None",
                UserRole = UserRole.SYSTEM,
                ImageUrl = "",
                Birth = DateTime.UtcNow,
                RegisteredAt = DateTime.UtcNow,
                ProfileAccessibility = ProfileAccessibility.PUBLIC,
                Theme = Theme.LIGHT,
                Language = Language.ENGLISH,
                ReceiveEmailNotifications = false,
                EnableDoubleFactorAuthentication = false
            };

            //Add the new system admin to the database
            _db.Users.Add(systemUser);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Admin",
                ip,
                id,
                PrivacyLevel.WARNING,
                "Successful Operation - System Admin Reset"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.reset", new
            {
                systemAdminId = id,
                resetBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "System Admin reset successfully!" });
        }

        /// <summary>
        /// Seeds the database with random fake data.
        /// </summary>
        /// <returns></returns>
        [HttpPost("seed/{password}")]
        [Authorize(Policy = "SuperAdmins")]
        public async Task<IActionResult> Seed(string password)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Seed the database in correct order
            List<Guid> userIds = await _seeder.SeedAsync<User, Guid>(50, null, null, null, password);
            await _seeder.SeedAsync<Notification, Guid>(50, userIds, null, null, password);

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Admin",
                ip,
                Guid.Empty,
                PrivacyLevel.WARNING,
                "Successful Operation - Seeded The Database With Random Rows"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.seeded", new
            {
                seededBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Database seeded successfully!" });
        }
    }
}
