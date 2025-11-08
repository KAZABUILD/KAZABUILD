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
        [StringLength(128, ErrorMessage = "Question cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Question must be at least 8 characters long!")]
        public string Question { get; set; } = default!;
    }
}
