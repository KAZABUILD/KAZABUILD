using FluentValidation;
using KAZABUILD.Domain.Enums;
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

        [StringLength(1000, ErrorMessage = "Description must be shorter than 1001 characters!")]
        public string? Description { get; set; }

        [StringLength(20, ErrorMessage = "Gender must be shorter than 10 characters!")]
        public string? Gender { get; set; }

        [Url(ErrorMessage = "Invalid image URL!")]
        public string? ImageUrl { get; set; }

        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string? Password { get; set; }

        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string? Email { get; set; }

        public UserRole? UserRole { get; set; }
    }
}
