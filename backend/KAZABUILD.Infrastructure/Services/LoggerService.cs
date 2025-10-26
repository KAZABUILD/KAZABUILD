using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.Extensions.Logging;
using Serilog.Core;
using System.Text.Json;

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

        //Filepath for stashing logs and a serializer for json
        private readonly string _stashFilepath = Path.Combine(AppContext.BaseDirectory, "failed_logs.json");
        private readonly JsonSerializerOptions jsonSerializerOptions = new() { WriteIndented = true };

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

            try
            {
                //Add the log to the database and save changes
                _db.Logs.Add(log);
                await _db.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                // Log locally to Serilog so at least we know it failed
                _serilogLogger.LogError(ex, "Failed to write log to database. Stashing locally.");

                await StashLogAsync(log);
            }

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

        /// <summary>
        /// Stashes logs which are impossible to be logged at the moment.
        /// </summary>
        /// <param name="log"></param>
        /// <returns></returns>
        public async Task StashLogAsync(Log log)
        {
            //Declare a list of stashed logs
            List<Log> stashed = [];

            //Get the file with already stashed logs
            if (File.Exists(_stashFilepath))
            {
                //Read the contents of the file
                var json = await File.ReadAllTextAsync(_stashFilepath);

                //Deserialize the json into the list
                stashed = JsonSerializer.Deserialize<List<Log>>(json) ?? [];
            }

            //add a log to the list
            stashed.Add(log);

            //Serialize the list into json again
            var newJson = JsonSerializer.Serialize(stashed, jsonSerializerOptions);

            //Write the logs into a file
            await File.WriteAllTextAsync(_stashFilepath, newJson);
        }

        /// <summary>
        /// Adds all stashed logs to the database.
        /// </summary>
        /// <returns></returns>
        public async Task FlushStashedLogsAsync()
        {
            //Check if the stashed file exists
            if (!File.Exists(_stashFilepath))
                return;

            //Read the contents of the file
            var json = await File.ReadAllTextAsync(_stashFilepath);

            //Deserialize the json into a list
            var stashedLogs = JsonSerializer.Deserialize<List<Log>>(json);

            //Exit function if there are no stashed logs
            if (stashedLogs == null || stashedLogs.Count == 0)
                return;

            try
            {
                //Add all stashed logs to the database
                _db.Logs.AddRange(stashedLogs);

                //Save changes to the database
                await _db.SaveChangesAsync();

                //Delete the stashed file
                File.Delete(_stashFilepath);

                //Log the flush
                _serilogLogger.LogInformation("Successfully flushed {Count} stashed logs to the database.", stashedLogs.Count);
            }
            catch (Exception ex)
            {
                _serilogLogger.LogError(ex, "Failed to flush stashed logs.");
            }
        }
    }
}
