using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Security
{
    public static class RoleGroups
    {
        public static readonly string[] AllUsers =
        [
            UserRole.GUEST.ToString(),
            UserRole.UNVERIFIED.ToString(),
            UserRole.USER.ToString(),
            UserRole.VIP.ToString(),
            UserRole.MODERATOR.ToString(),
            UserRole.ADMINISTRATOR.ToString(),
            UserRole.OWNER.ToString(),
            UserRole.SYSTEM.ToString()
        ];

        public static readonly string[] Staff =
        [
            UserRole.MODERATOR.ToString(),
            UserRole.ADMINISTRATOR.ToString(),
            UserRole.OWNER.ToString(),
            UserRole.SYSTEM.ToString()
        ];

        public static readonly string[] Admins =
        [
            UserRole.ADMINISTRATOR.ToString(),
            UserRole.OWNER.ToString(),
            UserRole.SYSTEM.ToString()
        ];

        public static readonly string[] SuperAdmins =
        [
            UserRole.OWNER.ToString(),
            UserRole.SYSTEM.ToString()
        ];
    }
}
