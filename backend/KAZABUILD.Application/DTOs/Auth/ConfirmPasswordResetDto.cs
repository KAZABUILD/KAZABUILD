using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Used for confirming user Password Reset through email.
    /// </summary>
    public class ConfirmPasswordResetDto
    {
        /// <summary>
        /// The toke used to verify Password Reset.
        /// </summary>
        [Required]
        public string Token { get; set; } = default!;

        /// <summary>
        /// New Password set by the user. Later hashed and discarded.
        /// </summary>
        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string NewPassword { get; set; } = default!;
    }
}
