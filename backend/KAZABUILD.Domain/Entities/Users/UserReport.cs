using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model representing a Report submitted by a User concerning another User.
    /// </summary>
    public class UserReport
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the User who Reported the other User.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Type of the model being Targeted by the Report.
        /// </summary>
        [Required]  
        [EnumDataType(typeof(ReportTargetType))]
        public ReportTargetType TargetType { get; set; } = default!;

        //Possible references, only one should ever be set at a time
        /// <summary>
        /// Id of the Forum Post this Report is about.
        /// Can be null as a Report should be made about only one object.
        /// </summary>
        public Guid? ForumPostId { get; set; }

        /// <summary>
        /// Id of the Build this Report is about.
        /// Can be null as a Report should be made about only one object.
        /// </summary>
        public Guid? BuildId { get; set; }

        /// <summary>
        /// Id of the Comment this Report is about.
        /// Can be null as a Report should be made about only one object.
        /// </summary>
        public Guid? UserCommentId { get; set; }

        /// <summary>
        /// Id of the User this Report is about.
        /// Can be null as a Report should be made about only one object.
        /// </summary>
        public Guid? ReportedUserId { get; set; }

        /// <summary>
        /// Id of the Message this Report is about.
        /// Can be null as a Report should be made about only one object.
        /// </summary>
        [Required]
        public Guid? MessageId { get; set; } = default!;

        /// <summary>
        /// Short reason for the report, (e.g., Harassment, Posting Nudity).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Reason cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Reason must be at least 3 characters long!")]
        public string Reason { get; set; } = default!;

        /// <summary>
        /// Detailed explanation of the reason for the Report.
        /// </summary>
        [Required]
        [StringLength(500, ErrorMessage = "Details cannot be longer than 500 characters!")]
        [MinLength(10, ErrorMessage = "Details must be at least 10 characters long!")]
        public string Details { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public User? ReportedUser { get; set; } = default!;
        public Message? Message { get; set; } = default!;
        public ForumPost? ForumPost { get; set; } = default!;
        public Build? Build { get; set; } = default!;
        public UserComment? UserComment { get; set; } = default!;
    }
}
