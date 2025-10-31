using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserReport
{
    public class UpdateUserReportDto
    {
        /// <summary>
        /// Short reason for the report, (e.g., Harassment, Posting Nudity).
        /// </summary>
        [StringLength(50, ErrorMessage = "Reason cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Reason must be at least 3 characters long!")]
        public string? Reason { get; set; }

        /// <summary>
        /// Detailed explanation of the reason for the Report.
        /// </summary>
        [StringLength(500, ErrorMessage = "Details cannot be longer than 500 characters!")]
        [MinLength(10, ErrorMessage = "Details must be at least 10 characters long!")]
        public string? Details { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
