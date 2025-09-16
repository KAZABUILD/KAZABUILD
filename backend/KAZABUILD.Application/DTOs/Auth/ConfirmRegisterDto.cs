using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    public class ConfirmRegisterDto
    {
        [Required]
        public string Token { get; set; } = default!;
    }
}
