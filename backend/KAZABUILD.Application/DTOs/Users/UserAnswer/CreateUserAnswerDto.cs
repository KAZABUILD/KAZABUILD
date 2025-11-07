using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserAnswer
{
    public class CreateUserAnswerDto
    {
        /// <summary>
        /// Id of the user that set the preferences.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the answer the question relates to.
        /// Nullable if it's one of the main questions.
        /// </summary>
        [Required]
        public Guid UserPreferenceAnswerId { get; set; }
    }
}
