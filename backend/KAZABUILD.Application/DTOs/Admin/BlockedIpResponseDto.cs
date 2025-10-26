using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Admin
{
    public class BlockedIpResponseDto
    {
        public Guid Id { get; set; }

        public string? IpAddress { get; set; }

        public DateTime? CreatedAt { get; set; }

        public Guid? BlockedByUserId { get; set; }

        public string? Reason { get; set; }
    }
}
