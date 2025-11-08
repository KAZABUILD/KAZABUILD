using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing an answer user selected while answering a questionnaire.
    /// </summary>
    public class UserAnswer
    {
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public UserPreferenceAnswer UserPreferenceAnswer { get; set; } = default!;
    }
}
