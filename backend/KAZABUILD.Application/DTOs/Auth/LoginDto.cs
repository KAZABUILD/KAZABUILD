using KAZABUILD.Application.Validators;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Used for user login.
    /// Requires either Login or Email to be provided.
    /// </summary>
    [RequireAtLeastOne(nameof(Login), nameof(Email))]
    public class LoginDto
    {
        /// <summary>
        /// User Login. Has to be unique.
        /// </summary>
        public string? Login { get; set; }

        /// <summary>
        /// User Email. Has to be unique.
        /// </summary>
        public string? Email { get; set; }

        /// <summary>
        /// Password set by the user. Later hashed and discarded.
        /// </summary>
        [Required]
        public string Password { get; set; } = default!;
    }
}
