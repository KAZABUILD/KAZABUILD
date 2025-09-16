using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.Extensions.Logging;
using Serilog.Core;

namespace KAZABUILD.Infrastructure.Services
{
    public class LoggerService(KAZABUILDDBContext db, ILogger<Logger> serilogLogger) : ILoggerService
    {
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILogger<Logger> _serilogLogger = serilogLogger;

        //Logs an event to the database
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

            //Check if there is an ip address and format it correctly
            var ip = string.IsNullOrEmpty(ipAddress) ? "" : $" ({ipAddress})";

            //Check if there is a target and format it correctly
            var _targetId = targetId == Guid.Empty ? "" : $" (Target: {targetId})";

            //Check if there is a target and format it correctly
            var _userId = userId == Guid.Empty ? "" : $" by {userId}";

            //Crate a serilog message
            string message = $"{activityType} on {targetType}{_userId}{ip}{_targetId} - {description ?? "No description"}";

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
