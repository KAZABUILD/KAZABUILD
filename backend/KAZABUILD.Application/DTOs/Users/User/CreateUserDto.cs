using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.User
{
    public class CreateUserDto
    {
        [Required]
        [StringLength(50, ErrorMessage = "Login cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Login must be at least 8 characters long!")]
        public string Login { get; set; } = default!;

        [Required]
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string Email { get; set; } = default!;

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string Password { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Display name cannot be longer than 50 characters!")]
        [MinLength(4, ErrorMessage = "Display Name must be at least 4 characters long!")]
        public string DisplayName { get; set; } = default!;

        [Phone(ErrorMessage = "Invalid phone number format!")]
        public string? PhoneNumber { get; set; }

        [StringLength(1000, ErrorMessage = "Description cannot be longer than 1000 characters!")]
        public string? Description { get; set; } = "";

        [Required]
        [StringLength(20, ErrorMessage = "Gender cannot be longer than 20 characters!")]
        public string Gender { get; set; } = "Unknown";

        [Required]
        [EnumDataType(typeof(UserRole))]
        public UserRole UserRole { get; set; } = UserRole.GUEST;

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid image URL!")]
        public string ImageUrl { get; set; } = "wwwroot/defaultuser.png";

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Birth { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; }

        public Address? Address { get; set; }

        [EnumDataType(typeof(ProfileAccessibility))]
        public ProfileAccessibility ProfileAccessibility { get; set; } = ProfileAccessibility.FOLLOWS;

        [EnumDataType(typeof(Theme))]
        public Theme Theme { get; set; } = Theme.DARK;

        [EnumDataType(typeof(Language))]
        public Language Language { get; set; } = Language.ENGLISH;

        [StringLength(100, ErrorMessage = "Location cannot be longer than 100 characters!")]
        public string? Location { get; set; }

        public bool ReceiveEmailNotifications { get; set; } = true;

        public bool EnableDoubleFactorAuthentication { get; set; } = false;
    }
}
