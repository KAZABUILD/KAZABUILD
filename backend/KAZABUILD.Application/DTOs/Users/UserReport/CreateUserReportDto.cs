using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserReport
{
    public class CreateUserReportDto
    {
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

        /// <summary>
        /// Id of the object this Report is about.
        /// Which object it's applied to depends on the ReportTargetType set.
        /// </summary>
        public Guid? TargetId { get; set; }

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
    }
}
