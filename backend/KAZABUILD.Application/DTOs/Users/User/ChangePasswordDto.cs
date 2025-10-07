using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.User
{
    /// <summary>
    /// Used to change user's password when user is logged in.
    /// </summary>
    public class ChangePasswordDto
    {
        /// <summary>
        /// Old unhashed user password used to verify.
        /// </summary>
        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string OldPassword { get; set; } = default!;

        /// <summary>
        /// New Password decided by the user. Later hashed and discarded.
        /// </summary>
        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string NewPassword { get; set; } = default!;
    }
}
