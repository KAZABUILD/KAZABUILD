using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class Verify2FactorAuthenticationDto
    {
        [Required]
        public string Token { get; set; } = default!;
    }
}
