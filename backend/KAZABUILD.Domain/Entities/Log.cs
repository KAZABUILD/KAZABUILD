using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    /// <summary>
    /// Model storing information about events happening in the program.
    /// </summary>
    public class Log
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the User that called the activity being logged. 
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// When the activity took place.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Importance of the event.
        /// </summary>
        [Required]
        public PrivacyLevel SeverityLevel { get; set; } = PrivacyLevel.INFORMATION;

        /// <summary>
        /// What type of activity took place.
        /// </summary>
        [Required]
        public string ActivityType { get; set; } = default!;

        /// <summary>
        /// Where the activity took place.
        /// </summary>
        [Required]
        public string TargetType { get; set; } = default!;

        /// <summary>
        /// Id of the target of the activity. Null if nonapplicable.
        /// </summary>
        public Guid? TargetId { get; set; }

        /// <summary>
        /// Nullable detailed description of the activity.
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// Nullable IP Address of the user that called the activity.
        /// </summary>
        public string? IpAddress { get; set; }
    }
}
