using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing an answer the user can select while answering a question in the questionnaire.
    /// </summary>
    public class UserPreferenceAnswer
    {
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public UserPreference? UserPreference { get; set; } = default!;
        public ICollection<UserAnswer> UserAnswers { get; set; } = [];
        public UserPreference SubUserPreference { get; set; } = default!;
    }
}
