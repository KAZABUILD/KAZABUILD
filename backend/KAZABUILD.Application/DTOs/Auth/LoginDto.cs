using KAZABUILD.Application.Validators;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    [RequireAtLeastOne(nameof(Login), nameof(Email))]
    public class LoginDto
    {
        public string? Login { get; set; }

        public string? Email { get; set; }

        [Required]
        public string Password { get; set; } = default!;
    }
}
