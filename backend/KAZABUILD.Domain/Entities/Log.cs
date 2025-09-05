using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class Log
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid UserId { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [Required]
        public PrivacyLevel SeverityLevel { get; set; } = PrivacyLevel.INFORMATION;

        [Required]
        public string ActivityType { get; set; } = default!;

        [Required]
        public string TargetType { get; set; } = default!;

        public Guid? TargetId { get; set; }

        public string? Description { get; set; }

        public string? IpAddress { get; set; }
    }
}
