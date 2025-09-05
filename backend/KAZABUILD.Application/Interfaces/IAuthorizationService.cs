using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Interfaces
{
    public interface IAuthorizationService
    {
        string GenerateJwtToken(Guid userId, string email, UserRole role);
    }
}
