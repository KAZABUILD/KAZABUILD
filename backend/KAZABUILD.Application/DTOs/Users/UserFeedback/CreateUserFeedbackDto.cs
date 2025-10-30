using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFeedback
{
    public class CreateUserFeedbackDto
    {
        /// <summary>
        /// The Id of the user leaving the feedback.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// The text of the feedback.
        /// </summary>
        [Required]
        [StringLength(5000, ErrorMessage = "Feedback cannot be longer than 5000 characters!")]
        [MinLength(20, ErrorMessage = "Feedback must be at least 20 characters long!")]
        public string Feedback { get; set; } = default!;
    }
}
