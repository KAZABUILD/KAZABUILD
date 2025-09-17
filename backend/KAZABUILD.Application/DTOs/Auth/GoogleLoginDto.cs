using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class GoogleLoginDto
    {
        [Required]
        public string IdToken { get; set; } = default!;
    }
}
