using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.User
{
    public class CreateUserDto
    {
        [Required]
        [StringLength(50)]
        [MinLength(8)]
        public string Login { get; set; } = default!;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = default!;

        [Required]
        [MinLength(8)]
        public string Password { get; set; } = default!;

        [Required]
        [StringLength(50)]
        [MinLength(8)]
        public string DisplayName { get; set; } = default!;

        [Phone]
        public string? PhoneNumber { get; set; }

        [StringLength(1000)]
        public string? Description { get; set; } = "";

        [Required]
        [StringLength(20)]
        public string Gender { get; set; } = "Unknown";

        [Required]
        public UserRole UserRole { get; set; } = UserRole.GUEST;

        [Required]
        [StringLength(255)]
        [Url]
        public string ImageUrl { get; set; } = "wwwroot/defaultuser.png";

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Birth { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; }

        public Address? Address { get; set; }

        public ProfileAccessibility ProfileAccessibility { get; set; } = ProfileAccessibility.FOLLOWS;

        public Theme Theme { get; set; } = Theme.DARK;

        public Language Language { get; set; } = Language.ENGLISH;

        public string? Location { get; set; }

        public bool ReceiveEmailNotifications { get; set; } = true;
    }
}
