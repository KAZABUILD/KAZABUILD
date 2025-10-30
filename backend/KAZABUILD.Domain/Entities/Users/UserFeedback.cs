using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Allows the user to send feedback related to the functioning of the website.
    /// </summary>
    public class UserFeedback
    {
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
    }
}
