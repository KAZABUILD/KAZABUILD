using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFeedback
{
    public class UpdateUserFeedbackDto
    {
        /// <summary>
        /// The Id of the user leaving the feedback.
        /// </summary>
        [Required]
        public Guid? UserId { get; set; }

        /// <summary>
        /// The text of the feedback.
        /// </summary>
        [Required]
        [StringLength(5000, ErrorMessage = "Feedback cannot be longer than 5000 characters!")]
        [MinLength(20, ErrorMessage = "Feedback must be at least 20 characters long!")]
        public string? Feedback { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
