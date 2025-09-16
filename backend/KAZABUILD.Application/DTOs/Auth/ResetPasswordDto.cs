using KAZABUILD.Application.Validators;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class ResetPasswordDto
    {

        [Required]
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string Email { get; set; } = default!;

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [RelativePath(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;
    }
}
