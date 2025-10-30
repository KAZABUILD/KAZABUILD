using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using KAZABUILD.Infrastructure.Services;

namespace KAZABUILD.Tests.Utils
{

    public static class UserFactory
    {
        private static Random _random = new Random();
        private static HashingService _hashingService = new();
        public static User GenerateUser(
            string? login = null,
            string? email = null,
            string? displayName = null,
            string? phone = null,
            string? gender = null,
            UserRole? role = null,
            string? imageUrl = null,
            DateTime? birth = null,
            Address? address = null,
            ProfileAccessibility? profileAccessibility = null,
            Theme? theme = null,
            Language? language = null,
            string? location = null
        )
        {
            return new User
            {
                Id = Guid.NewGuid(),
                Login = login ?? DbTestUtils.RandomString(10),
                Email = email ?? DbTestUtils.RandomEmail(),
                PasswordHash = _hashingService.Hash("Password123"),
                DisplayName = displayName ?? DbTestUtils.RandomString(12),
                PhoneNumber = phone ?? DbTestUtils.RandomPhone(),
                Description = "This is a test user description.",
                Gender = gender ?? "Unknown",
                UserRole = role ?? UserRole.GUEST,
                ImageUrl = imageUrl ?? DbTestUtils.RandomUrl(),
                Birth = birth ?? DateTime.UtcNow.AddYears(-_random.Next(18, 50)),
                RegisteredAt = DateTime.UtcNow,
                Address = address,
                ProfileAccessibility = profileAccessibility ?? ProfileAccessibility.FOLLOWS,
                Theme = theme ?? Theme.DARK,
                Language = language ?? Language.ENGLISH,
                Location = location ?? "Test Location",
                ReceiveEmailNotifications = _random.Next(0, 2) == 1,
                EnableDoubleFactorAuthentication = false,
                GoogleId = null,
                GoogleProfilePicture = null,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow,
                Note = "Test Note",
                Followers = [],
                Followed = [],
                UserTokens = [],
                UserPreferences = [],
                UserComments = [],
                ForumPosts = [],
                ReceivedMessages = [],
                SentMessages = [],
                Notifications = []
            };
        }
    }
}
