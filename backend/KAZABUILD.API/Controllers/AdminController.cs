using KAZABUILD.Application.DTOs.Admin;
using KAZABUILD.Application.DTOs.Users.User;
using KAZABUILD.Application.DTOs.Users.UserFollow;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Components.SubComponents;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;

namespace KAZABUILD.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AdminController(KAZABUILDDBContext db, IHashingService hasher, ILoggerService logger, IRabbitMQPublisher publisher, IDataSeeder seeder, IOptions<SystemAdminSetings> systemAdminSettigns, IOptions<SmtpSettings> SmtpServiceSettings, IWebHostEnvironment env) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly IHashingService _hasher = hasher;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IDataSeeder _seeder = seeder;
        private readonly SystemAdminSetings _systemAdminSettigns = systemAdminSettigns.Value;
        private readonly SmtpSettings _smtpServiceSettings = SmtpServiceSettings.Value;
        private readonly IWebHostEnvironment _env = env;

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
                ImageId = null,
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
        /// Only accessible in development.
        /// </summary>
        /// <returns></returns>
        [HttpPost("seed/{password}")]
        [Authorize(Policy = "SuperAdmins")]
        public async Task<IActionResult> Seed(string password)
        {
            //Only allowed in development
            if (!(_env.IsDevelopment() || _env.IsEnvironment("Testing")))
                return Forbid("Seeding is only allowed in Development environment!");

            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Seed the database in correct order
            List<Guid> userIds = await _seeder.SeedAsync<User, Guid>(count: 70, password: password);
            await _seeder.SeedAsync<Notification, Guid>(500, userIds);
            List<Guid> forumIds = await _seeder.SeedAsync<ForumPost, Guid>(200, userIds);

            //Seed multiple times to test parent messages
            await _seeder.SeedAsync<Message, Guid>(200, userIds);
            await _seeder.SeedAsync<Message, Guid>(400, userIds);
            await _seeder.SeedAsync<Message, Guid>(400, userIds);

            //Seed remaining user domain tables
            await _seeder.SeedAsync<UserFollow, Guid>(100, userIds);
            await _seeder.SeedAsync<UserPreference, Guid>(100, userIds);
            await _seeder.SeedAsync<UserFeedback, Guid>(50, userIds);

            //Seed all component variants
            List<Guid> componentIds = await _seeder.SeedAsync<CaseComponent, Guid>(30);
            componentIds.AddRange(await _seeder.SeedAsync<CaseFanComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<CoolerComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<CPUComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<GPUComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<MemoryComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<MonitorComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<MotherboardComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<PowerSupplyComponent, Guid>(30));
            componentIds.AddRange(await _seeder.SeedAsync<StorageComponent, Guid>(30));

            //Seed all subComponent variants
            List<Guid> subComponentIds = await _seeder.SeedAsync<CoolerSocketSubComponent, Guid>(20);
            subComponentIds.AddRange(await _seeder.SeedAsync<M2SlotSubComponent, Guid>(20));
            subComponentIds.AddRange(await _seeder.SeedAsync<IntegratedGraphicsSubComponent, Guid>(20));
            subComponentIds.AddRange(await _seeder.SeedAsync<OnboardEthernetSubComponent, Guid>(20));
            subComponentIds.AddRange(await _seeder.SeedAsync<PCIeSlotSubComponent, Guid>(20));
            subComponentIds.AddRange(await _seeder.SeedAsync<PortSubComponent, Guid>(20));

            //Seed the rest of the component domain tables
            List<string> colorCodes = await _seeder.SeedAsync<Color, string>(50);
            await _seeder.SeedAsync<ComponentPart, Guid>(400, componentIds, subComponentIds);
            await _seeder.SeedAsync<ComponentCompatibility, Guid>(500, componentIds);
            await _seeder.SeedAsync<ComponentPrice, Guid>(300, componentIds);
            List<Guid> componentReviewIds = await _seeder.SeedAsync<ComponentReview, Guid>(300, componentIds);
            List<Guid> colorVariantIds = await _seeder.SeedAsync<ComponentVariant, Guid>(500, componentIds);
            await _seeder.SeedAsync<ColorVariant, Guid>(800, colorVariantIds, idsOptional: colorCodes);

            //Seed all build domain tables
            List<Guid> buildIds = await _seeder.SeedAsync<Build, Guid>(200, userIds);
            List<Guid> tagIds = await _seeder.SeedAsync<Tag, Guid>(500);
            await _seeder.SeedAsync<BuildTag, Guid>(3000, buildIds, tagIds);
            await _seeder.SeedAsync<BuildComponent, Guid>(1200, buildIds, componentIds);
            await _seeder.SeedAsync<BuildInteraction, Guid>(2000, userIds, buildIds);

            //Seed the user activity
            await _seeder.SeedAsync<UserActivity, Guid>(10000, userIds, buildIds, forumIds);

            //Seed multiple times to test parent comments
            await _seeder.SeedAsync<UserComment, Guid>(500, userIds, forumIds, buildIds, componentIds, componentReviewIds);
            await _seeder.SeedAsync<UserComment, Guid>(1000, userIds, forumIds, buildIds, componentIds, componentReviewIds);
            await _seeder.SeedAsync<UserComment, Guid>(1000, userIds, forumIds, buildIds, componentIds, componentReviewIds);

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

        /// <summary>
        /// Allows the super admins to reset the whole database.
        /// Only accessible in development.
        /// </summary>
        /// <returns></returns>
        [HttpPost("reset-database")]
        [Authorize(Policy = "SuperAdmins")]
        public async Task<IActionResult> ResetDatabase()
        {
            //Only allowed in development
            if (!(_env.IsDevelopment() || _env.IsEnvironment("Testing")))
                return Forbid("Seeding is only allowed in Development environment!");

            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get all table names
            var tableNames = _db.Model.GetEntityTypes()
                .Select(t => t.GetTableName())
                .Distinct()
                .ToList();

            //Go through every table and reset them
            foreach (var tableName in tableNames)
            {
                _db.Database.ExecuteSql($"DELETE FROM [{tableName}]");
            }

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Admin",
                ip,
                Guid.Empty,
                PrivacyLevel.WARNING,
                "Successful Operation - Database Reset"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.database.reset", new
            {
                resetBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Database reset successfully!" });
        }

        /// <summary>
        /// Allows the administration to block an ip address from accessing the website.
        /// Adds the ip address to a blocklist.
        /// </summary>
        /// <param name="request"></param>
        /// <returns></returns>
        [HttpPost("block-ip")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> BlockIp([FromBody] BlockIpRequestDto request)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Ip is already blocked
            if (await _db.BlockedIps.AnyAsync(b => b.IpAddress == request.IpAddress))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Admin",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - The Ip Is Already Blocked"
                );

                //Return a conflict response
                return Conflict(new { message = "This Ip is already blocked!" });
            }

            //Create an ip block object
            var blockedIp = new BlockedIp
            {
                IpAddress = request.IpAddress,
                BlockedByUserId = currentUserId,
                CreatedAt = DateTime.UtcNow,
                Reason = request.Reason
            };

            //Add the new blockedIp to the database
            _db.BlockedIps.Add(blockedIp);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Admin",
                ip,
                blockedIp.Id,
                PrivacyLevel.CRITICAL,
                $"Successful Operation - Blocked New Ip From Accessing The Website"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.blockedIp", new
            {
                blockedIpId = blockedIp.Id,
                resetBy = currentUserId
            });

            //Return success response
            return Ok(new { message = $"Ip successfully blocked!" });
        }

        /// <summary>
        /// Allows the administration to get the full list of blocked Ip addresses.
        /// </summary>
        /// <returns></returns>
        [HttpGet("block-ip")]
        [Authorize(Policy = "Admins")]
        public async Task<ActionResult<BlockedIpResponseDto>> GetBlocklist()
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the blocklist
            List<BlockedIp> blocklist = await _db.BlockedIps.ToListAsync();

            //Declare response variable
            List<BlockedIpResponseDto> responses;

            //Create a userFollow response list
            responses = [.. blocklist.Select(blockedIp =>
            {
                //Return a blockedIp response
                return new BlockedIpResponseDto
                {
                    Id = blockedIp.Id,
                    IpAddress = blockedIp.IpAddress,
                    CreatedAt = blockedIp.CreatedAt,
                    BlockedByUserId = blockedIp.BlockedByUserId,
                    Reason = blockedIp.Reason,
                };
            })];

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserFollow",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - Amin Access"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.gotBlocklist", new
            {
                blockedIpIds = blocklist.Select(f => f.Id),
                resetBy = currentUserId
            });

            //Return success response
            return Ok(responses);
        }

        /// <summary>
        /// Allows the administration to unblock ip addresses and allow users using them to access the website again.
        /// </summary>
        /// <param name="ipAddress"></param>
        /// <returns></returns>
        [HttpDelete("block-ip/{ipAddress}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UnblockIp(string ipAddress)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Ip is in the blocklist
            var blockedIp = await _db.BlockedIps.FirstOrDefaultAsync(b => b.IpAddress == ipAddress);
            if (blockedIp == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Admin",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - The Ip Is Already Blocked"
                );

                return NotFound(new { message = "Ip not found in blocklist!" });
            }

            //Remove the block from the database
            _db.BlockedIps.Remove(blockedIp);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Admin",
                ip,
                blockedIp.Id,
                PrivacyLevel.CRITICAL,
                $"Successful Operation - Ip Allowed Access To The Website Again"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("admin.unblockedIp", new
            {
                blockedIpId = blockedIp.Id,
                resetBy = currentUserId
            });

            //Return success response
            return Ok(new { message = $"Ip has been unblocked!" });
        }
    }
}
