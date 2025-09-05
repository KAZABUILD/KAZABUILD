using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

namespace KAZABUILD.Infrastructure.Services
{
    public class Logger(KAZABUILDDBContext db) : ILogger
    {
        private readonly KAZABUILDDBContext _db = db;

        //Logs an event to the database
        public async Task LogAsync(Guid userId, string activityType, string targetType, string? ipAddress, Guid targetId, PrivacyLevel severityLevel = PrivacyLevel.INFORMATION, string? description = null)
        {
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

            _db.Logs.Add(log);
            await _db.SaveChangesAsync();
        }
    }
}
