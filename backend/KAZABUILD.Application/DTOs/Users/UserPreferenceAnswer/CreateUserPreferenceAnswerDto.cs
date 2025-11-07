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
        public string Answer { get; set; } = default!;
    }
}
