using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class ConfirmPasswordResetDto
    {
        [Required]
        public string Token { get; set; } = default!;

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string NewPassword { get; set; } = default!;
    }
}
