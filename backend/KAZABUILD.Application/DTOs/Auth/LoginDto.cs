using KAZABUILD.Application.Validators;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    [RequireAtLeastOne(nameof(Login), nameof(Email))]
    public class LoginDto
    {
        public string? Login;

        public string? Email;

        [Required]
        public string Password = default!;
    }
}
