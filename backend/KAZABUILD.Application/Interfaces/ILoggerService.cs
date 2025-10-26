using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Interfaces
{
    public interface ILoggerService
    {
        Task LogAsync(Guid UserId, string ActivityType, string TargetType, string? IpAddress, Guid TargetId, PrivacyLevel level = PrivacyLevel.INFORMATION, string? Description = null);
        Task StashLogAsync(Log log);
        Task FlushStashedLogsAsync();
    }
}
