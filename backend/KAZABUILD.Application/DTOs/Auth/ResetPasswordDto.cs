using KAZABUILD.Application.Validators;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Used for resetting user passwords.
    /// </summary>
    public class ResetPasswordDto
    {
        /// <summary>
        /// Current email used in an account.
        /// </summary>
        [Required]
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string Email { get; set; } = default!;

        /// <summary>
        /// Redirect Url provided by the frontend to redirect to page on the website for custom behaviour.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [RelativePath(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;
    }
}
