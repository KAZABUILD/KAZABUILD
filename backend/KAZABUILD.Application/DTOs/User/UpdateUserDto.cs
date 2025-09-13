using FluentValidation;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.User
{
    public class UpdateUserDto
    {
        [StringLength(50, ErrorMessage = "Display name cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Display Name must be at least 8 characters long!")]
        public string? DisplayName { get; set; }

        [StringLength(50, ErrorMessage = "Login cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Login must be at least 8 characters long!")]
        public string? Login { get; set; }

        [Phone(ErrorMessage = "Invalid phone number format!")]
        public string? PhoneNumber { get; set; }

        [StringLength(1000, ErrorMessage = "Description cannot be longer than 1000 characters!")]
        public string? Description { get; set; }

        [StringLength(20, ErrorMessage = "Gender cannot be longer than 20 characters!")]
        public string? Gender { get; set; }

        [Url(ErrorMessage = "Invalid image URL!")]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        public string? ImageUrl { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? Birth { get; set; }

        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string? Password { get; set; }

        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string? Email { get; set; }

        [EnumDataType(typeof(UserRole))]
        public UserRole? UserRole { get; set; }

        public Address? Address { get; set; }

        [EnumDataType(typeof(ProfileAccessibility))]
        public ProfileAccessibility? ProfileAccessibility { get; set; }

        [EnumDataType(typeof(Theme))]
        public Theme? Theme { get; set; }

        [EnumDataType(typeof(Language))]
        public Language? Language { get; set; }

        [StringLength(100, ErrorMessage = "Location cannot be longer than 100 characters!")]
        public string? Location { get; set; }

        public bool? ReceiveEmailNotifications { get; set; }

        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
