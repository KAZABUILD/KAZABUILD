using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Message
{
    public class MessageResponseDto
    {
        public Guid Id { get; set; }

        public Guid? SenderId { get; set; }

        public Guid? ReceiverId { get; set; }

        public string? Content { get; set; }

        public string? Title { get; set; }

        public DateTime? SentAt { get; set; }

        public bool? IsRead { get; set; }

        public Guid? ParentMessageId { get; set; }

        public MessageType? MessageType { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
