using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserReport
{
    public class UserReportResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public ReportTargetType? TargetType { get; set; }

        public Guid? TargetId { get; set; }

        public string? Reason { get; set; }

        public string? Details { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
