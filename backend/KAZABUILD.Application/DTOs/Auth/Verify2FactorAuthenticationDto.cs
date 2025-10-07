using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Used for verifying 2FA.
    /// </summary>
    public class Verify2FactorAuthenticationDto
    {
        /// <summary>
        /// The toke used to double verify.
        /// </summary>
        [Required]
        public string Token { get; set; } = default!;
    }
}
