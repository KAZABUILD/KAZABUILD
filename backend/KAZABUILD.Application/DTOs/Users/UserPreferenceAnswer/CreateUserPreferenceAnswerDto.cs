using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreferenceAnswer
{
    public class CreateUserPreferenceAnswerDto
    {
        /// <summary>
        /// Id of the question this object is an answer to.
        /// </summary>
        [Required]
        public Guid UserPreferenceId { get; set; } = default!;

        /// <summary>
        /// Content of the Answer.
        /// </summary>
        [Required]
        [StringLength(128, ErrorMessage = "Answer cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Answer must be at least 8 characters long!")]
        public string Answer { get; set; } = default!;
    }
}
