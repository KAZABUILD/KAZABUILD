using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Interfaces
{
    public interface ILoggerService
    {
        /// <summary>
        /// Logs an event to the database.
        /// Additionally logs to a file and console as well.
        /// </summary>
        /// <param name="UserId"></param>
        /// <param name="ActivityType"></param>
        /// <param name="TargetType"></param>
        /// <param name="IpAddress"></param>
        /// <param name="TargetId"></param>
        /// <param name="level"></param>
        /// <param name="Description"></param>
        /// <returns></returns>
        Task LogAsync(Guid UserId, string ActivityType, string TargetType, string? IpAddress, Guid TargetId, PrivacyLevel level = PrivacyLevel.INFORMATION, string? Description = null);

        /// <summary>
        /// Stashes logs which are impossible to be logged at the moment.
        /// </summary>
        /// <param name="log"></param>
        /// <returns></returns>
        Task StashLogAsync(Log log);

        /// <summary>
        /// Adds all stashed logs to the database.
        /// </summary>
        /// <returns></returns>
        Task FlushStashedLogsAsync();
    }
}
