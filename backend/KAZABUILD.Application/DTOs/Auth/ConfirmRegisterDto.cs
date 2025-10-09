using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Used for confirming user registration through email.
    /// </summary>
    public class ConfirmRegisterDto
    {
        /// <summary>
        /// The toke used to verify registration.
        /// </summary>
        [Required]
        public string Token { get; set; } = default!;
    }
}
