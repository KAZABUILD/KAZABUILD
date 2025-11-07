using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreference
{
    public class CreateUserPreferenceDto
    {
        /// <summary>
        /// Id of the answer the question relates to.
        /// Nullable if it's one of the main questions.
        /// </summary>
        public Guid? UserPreferenceAnswerId { get; set; }

        /// <summary>
        /// Preference answered by the questionnaire
        /// </summary>
        [Required]
        public string Question { get; set; } = default!;
    }
}
