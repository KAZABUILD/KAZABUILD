using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Required for Google specific Login. 
    /// </summary>
    public class GoogleLoginDto
    {
        /// <summary>
        /// Token used to connect to google services and get user information.
        /// </summary>
        [Required]
        public string IdToken { get; set; } = default!;
    }
}
