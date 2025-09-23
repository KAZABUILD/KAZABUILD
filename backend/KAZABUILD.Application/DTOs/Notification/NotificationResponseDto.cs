using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Notification
{
    public class NotificationResponseDto
    {
        public Guid Id { get; set; }

        public Guid? UserId { get; set; }

        public NotificationType? NotificationType { get; set; }

        public string? Body { get; set; }

        public string? Title { get; set; }

        public string? LinkUrl { get; set; }

        public DateTime? SentAt { get; set; }

        public bool? IsRead { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
