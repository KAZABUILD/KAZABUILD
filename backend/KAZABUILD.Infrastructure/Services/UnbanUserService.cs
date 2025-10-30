using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Threading;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service that runs once a day to unban users whose ban expiry data has passed.
    /// </summary>
    /// <param name="scopeFactory"></param>
    public class UnbanUserService(IServiceScopeFactory scopeFactory) : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory = scopeFactory;

        /// <summary>
        /// The cleanup task executed once a day.
        /// </summary>
        /// <param name="stoppingToken"></param>
        /// <returns></returns>
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                //Create a scope for the database and logger and get them
                using var scope = _scopeFactory.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
                var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

                //Try to unban all users who fulfill the requirement to be unbanned
                try
                {
                    //Get the current date
                    var now = DateTime.UtcNow;

                    // Find all users who are banned and whose bans have expired
                    var expiredBans = await db.Users
                        .Where(u => u.UserRole == UserRole.BANNED && u.BannedUntil != null && u.BannedUntil <= now)
                        .ToListAsync(stoppingToken);


                    //Check if any logs were cleaned
                    if (expiredBans.Count != 0)
                    {
                        //Adjust all necessary fields for newly unbanned users
                        foreach (var user in expiredBans)
                        {
                            user.UserRole = UserRole.USER;
                            user.BannedUntil = null;
                            user.LastEditedAt = now;
                        }

                        //Save changes to the database
                        await db.SaveChangesAsync(stoppingToken);

                        //Log unban
                        await logger.LogAsync(
                            Guid.Empty,
                            "Unban",
                            "UnbanUserService",
                            "",
                            Guid.Empty,
                            PrivacyLevel.INFORMATION,
                            $"Successful Operation - {expiredBans.Count} Users Unbanned"
                        );
                    }
                }
                catch (Exception ex)
                {
                    //Log failure
                    await logger.LogAsync(
                        Guid.Empty,
                        "Unban",
                        "UnbanUserService",
                        "",
                        Guid.Empty,
                        PrivacyLevel.INFORMATION,
                        $"Operation Failure - Failed the unban. Error Message: {ex}"
                    );
                }

                //Wait 24 hours before running again
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
        }
    }
}
