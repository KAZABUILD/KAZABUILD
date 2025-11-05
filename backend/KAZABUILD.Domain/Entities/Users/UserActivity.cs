using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Allows tracking of User Activity on the website as well as displaying it as views.
    /// </summary>
    public class UserActivity
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// The Id of the User who performed the activity.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// What type of activity the user performed.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Activity Type cannot be longer than 50 characters!")]
        public string ActivityType { get; set; } = default!;

        /// <summary>
        /// The target Id of the object which the activity was related to.
        /// It's a singular field unlike UserComment and similar since every model in the database could potentially have it's activity logged.
        /// </summary>
        [Required]
        public Guid TargetId { get; set; } = default!;

        /// <summary>
        /// When the activity happened.
        /// </summary>
        [Required]
        public DateTime Timestamp { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User User { get; set; } = default!;
    }
}
