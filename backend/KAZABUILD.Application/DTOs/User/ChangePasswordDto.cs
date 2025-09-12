using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.User
{
    public class ChangePasswordDto
    {
        [Required]
        public string OldPassword { get; set; } = default!;

        [Required]
        public string NewPassword { get; set; } = default!;
    }
}
