using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreference
{
    public class CreateUserPreferenceDto
    {
        /// <summary>
        /// Id of the user that set the preferences.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;
    }
}
