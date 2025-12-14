using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Diagnostics; 
using System.Diagnostics.Metrics; 

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service that runs once a day to cleanup old logs and token.
    /// Logs are cleaned after 3 months, tokens after 7 days. 
    /// </summary>
    /// <param name="scopeFactory"></param>
    public class CleanupService(IServiceScopeFactory scopeFactory) : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory = scopeFactory;

        // Metrics Definitions
        private static readonly Meter _meter = new("KazaBuild.Cleanup");
        private static readonly Histogram<double> _jobDuration = _meter.CreateHistogram<double>(
            "app_cleanup_job_duration_seconds", "s", "Duration of the daily cleanup job");
        private static readonly Counter<long> _itemsDeleted = _meter.CreateCounter<long>(
            "app_cleanup_items_deleted_total", description: "Total items deleted during cleanup");

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

                var stopwatch = Stopwatch.StartNew(); // Start timing
                //Try to cleanup old objects
                try
                {
                    //Create a cutoff for 7 days ago
                    var tokenCutoff = DateTime.UtcNow.AddDays(-7);

                    //Get used tokens (older than 7 days)
                    var oldTokens = await db.UserTokens
                        .Include(t => t.User)
                        .Where(t => t.UsedAt != null && t.UsedAt < tokenCutoff)
                        .ToListAsync(stoppingToken);

                    //Check if any logs were cleaned
                    if (oldTokens.Count != 0)
                    {
                        //Remove any users which haven't been verified after a week
                        var users = oldTokens.Where(t => t.TokenType == TokenType.CONFIRM_REGISTER).Select(t => t.User).Where(u => u != null && u.UserRole == UserRole.UNVERIFIED).ToList();
                        if(users.Count != 0)
                        {
                            db.Users.RemoveRange(users!);
                            _itemsDeleted.Add(users.Count, new KeyValuePair<string, object?>("type", "unverified_users"));
                        }

                        //Remove old used token
                        db.UserTokens.RemoveRange(oldTokens);

                        //Log Token cleanup
                        await logger.LogAsync(
                            Guid.Empty,
                            "Cleanup",
                            "CleanupService",
                            "",
                            Guid.Empty,
                            PrivacyLevel.INFORMATION,
                            "Successful Operation - Old Token Cleaned Up"
                        );
                    }

                    //Create a cutoff for 3 months ago
                    var logCutoff = DateTime.UtcNow.AddMonths(-3);

                    //Cleanup logs older than 3 months, except ERROR and CRITICAL level ones
                    var oldLogs = await db.Logs
                        .Where(l => l.Timestamp < logCutoff && l.SeverityLevel != PrivacyLevel.ERROR && l.SeverityLevel != PrivacyLevel.CRITICAL)
                        .ToListAsync(stoppingToken);

                    //Check if any logs were cleaned
                    if (oldLogs.Count != 0)
                    {
                        //Remove old logs
                        db.Logs.RemoveRange(oldLogs);
                        
                        _itemsDeleted.Add(oldLogs.Count, new KeyValuePair<string, object?>("type", "logs"));
                        
                        //Log Logs cleanup
                        await logger.LogAsync(
                            Guid.Empty,
                            "Cleanup",
                            "CleanupService",
                            "",
                            Guid.Empty,
                            PrivacyLevel.INFORMATION,
                            "Successful Operation - Old Logs Cleaned Up"
                        );
                    }

                    //Save changes to the database
                    await db.SaveChangesAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    //Log failure
                    await logger.LogAsync(
                        Guid.Empty,
                        "Cleanup",
                        "CleanupService",
                        "",
                        Guid.Empty,
                        PrivacyLevel.INFORMATION,
                        $"Operation Failure - Failed the daily cleanup. Error Message: {ex}"
                    );
                }
                finally
                {
                    // Stop timing and record duration
                    stopwatch.Stop();
                    _jobDuration.Record(stopwatch.Elapsed.TotalSeconds);
                }
                //Wait 24 hours before running again
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
        }
    }
}
