using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Interfaces
{
    public interface ILogger
    {
        Task LogAsync(Guid UserId, string ActivityType, string TargetType, string? IpAddress, Guid TargetId, PrivacyLevel level = PrivacyLevel.INFORMATION, string? Description = null);
    }
}
