using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing a question the user can answer in the questionnaire.
    /// </summary>
    public class UserPreference
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the answer the question is subject to.
        /// Nullable if it's one of the main questions.
        /// </summary>
        public Guid? UserPreferenceAnswerId { get; set; }

        /// <summary>
        /// Content of the Preference.
        /// </summary>
        [Required]
        public string Question { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public UserPreferenceAnswer UserPreferenceAnswer { get; set; } = default!;
        public ICollection<UserPreferenceAnswer> UserPreferenceAnswers { get; set; } = [];
    }
}
