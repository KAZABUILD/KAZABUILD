using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class UserRegisterDto
    {
        [Required]
        public required string Email { get; set; }

        [Required]
        public required string Password { get; set; }
    }
}
