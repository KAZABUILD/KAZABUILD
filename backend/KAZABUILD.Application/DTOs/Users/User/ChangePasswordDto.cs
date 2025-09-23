using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.User
{
    public class ChangePasswordDto
    {
        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string OldPassword { get; set; } = default!;

        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string NewPassword { get; set; } = default!;
    }
}
