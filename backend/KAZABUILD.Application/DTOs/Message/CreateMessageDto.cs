using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Message
{
    public class CreateMessageDto
    {
        [Required]
        public Guid SenderId { get; set; } = default!;

        [Required]
        public Guid ReceiverId { get; set; } = default!;

        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 50 characters!")]
        public string Content { get; set; } = default!;

        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime SentAt { get; set; } = default!;

        public bool IsRead { get; set; } = false;

        public Guid? ParentMessageId { get; set; }

        [Required]
        [EnumDataType(typeof(MessageType))]
        public MessageType MessageType { get; set; } = default!;
    }
}
