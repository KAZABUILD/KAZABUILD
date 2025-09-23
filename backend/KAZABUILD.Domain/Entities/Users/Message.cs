using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    public class Message
    {
        //Message fields
        [Key]
        public Guid Id { get; set; } = default!;

        [Required]
        public Guid SenderId { get; set; } = default!;

        [Required]
        public Guid ReceiverId { get; set; } = default!;

        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? Sender { get; set; } = default!;
        public User? Receiver { get; set; } = default!;
        public Message? ParentMessage { get; set; } = default!;
        public ICollection<Message> ChildMessages { get; set; } = [];
    }
}
