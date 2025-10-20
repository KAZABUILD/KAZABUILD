using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.Extensions.Logging;
using Serilog.Core;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service which logs information in the database, log files and the console.
    /// It's used in other services, controllers and the application startup.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="serilogLogger"></param>
    public class LoggerService(KAZABUILDDBContext db, ILogger<Logger> serilogLogger) : ILoggerService
    {
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILogger<Logger> _serilogLogger = serilogLogger;

        /// <summary>
        /// Logs an event to the database.
        /// Additionally logs to a file and console as well.
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="activityType"></param>
        /// <param name="targetType"></param>
        /// <param name="ipAddress"></param>
        /// <param name="targetId"></param>
        /// <param name="severityLevel"></param>
        /// <param name="description"></param>
        /// <returns></returns>
        public async Task LogAsync(Guid userId, string activityType, string targetType, string? ipAddress, Guid targetId, PrivacyLevel severityLevel = PrivacyLevel.INFORMATION, string? description = null)
        {
            //Create a new log entry
            var log = new Log
            {
                UserId = userId,
                Timestamp = DateTime.UtcNow,
                ActivityType = activityType,
                TargetType = targetType,
                IpAddress = ipAddress,
                TargetId = targetId,
                Description = description,
                SeverityLevel = severityLevel
            };

            //Add the log to the database and save changes
            _db.Logs.Add(log);
            await _db.SaveChangesAsync();

            //Check if there is an IP address and format it correctly
            var ip = string.IsNullOrWhiteSpace(ipAddress) ? "" : $" ({ipAddress})";

            //Check if there is a target and format it correctly
            var _targetId = targetId == Guid.Empty ? "" : $" (Target: {targetId})";

            //Check if there is a target and format it correctly
            var _userId = userId == Guid.Empty ? "" : $" by {userId}";

            //Check if there is a description and format it correctly
            var _description = string.IsNullOrWhiteSpace(description) ? "" : $" - {description}";

            //Crate a serilog message string
            string message = $"{DateOnly.FromDateTime(DateTime.UtcNow)}: {activityType} on {targetType}{_userId}{ip}{_targetId}{_description}";

            //Write the log to serilog depending on severity
            switch (severityLevel)
            {
                case PrivacyLevel.INFORMATION:
                    _serilogLogger.LogInformation(message);
                    break;
                case PrivacyLevel.WARNING:
                    _serilogLogger.LogWarning(message);
                    break;
                case PrivacyLevel.ERROR:
                    _serilogLogger.LogError(message);
                    break;
                default:
                    _serilogLogger.LogInformation(message);
                    break;
            }
        }
    }
}
