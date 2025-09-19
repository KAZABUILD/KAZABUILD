using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;

namespace KAZABUILD.Application.DTOs.User
{
    public class UserReponseDto
    {
        public Guid? Id { get; set; }

        public string? Login { get; set; } = default!;

        public string? Email { get; set; } = default!;

        public string? PasswordHash { get; set; } = default!;

        public string? DisplayName { get; set; } = default!;

        public string? PhoneNumber { get; set; }

        public string? Description { get; set; }

        public string? Gender { get; set; }

        public UserRole? UserRole { get; set; }

        public string? ImageUrl { get; set; }

        public DateTime? Birth { get; set; }

        public DateTime? RegisteredAt { get; set; }

        public Address? Address { get; set; }

        public ProfileAccessibility? ProfileAccessibility { get; set; }

        public Theme? Theme { get; set; }

        public Language? Language { get; set; }

        public string? Location { get; set; }

        public bool? ReceiveEmailNotifications { get; set; }

        public bool? EnableDoubleFactorAuthentication { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note {  get; set; }
    }
}
