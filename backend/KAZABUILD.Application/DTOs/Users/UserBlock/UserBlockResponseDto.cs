using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserBlock
{
    public class UserBlockResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public Guid? BlockedUserId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
