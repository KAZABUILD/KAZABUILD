using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreferenceAnswer
{
    public class UpdateUserPreferenceAnswerDto
    {
        /// <summary>
        /// Id of the question this object is an answer to.
        /// </summary>
        public Guid? UserPreferenceId { get; set; }

        /// <summary>
        /// Content of the Answer.
        /// </summary>
        [StringLength(128, ErrorMessage = "Answer cannot be longer than 50 characters!")]
        public string? Answer { get; set; }

        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
