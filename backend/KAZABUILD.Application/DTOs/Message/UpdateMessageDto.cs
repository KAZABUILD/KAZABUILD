using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Message
{
    public class UpdateMessageDto
    {
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string? Content { get; set; }

        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? SentAt { get; set; }

        public bool? IsRead { get; set; } = false;

        public Guid? ParentMessageId { get; set; }

        [EnumDataType(typeof(MessageType))]
        public MessageType? MessageType { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
