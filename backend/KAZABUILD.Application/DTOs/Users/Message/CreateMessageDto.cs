using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.Message
{
    public class CreateMessageDto
    {
        /// <summary>
        /// Id of the sender.
        /// </summary>
        [Required]
        public Guid SenderId { get; set; } = default!;

        /// <summary>
        /// Id of the person receiving the message.
        /// </summary>
        [Required]
        public Guid ReceiverId { get; set; } = default!;

        /// <summary>
        /// Text content of the message.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string Content { get; set; } = default!;

        /// <summary>
        /// Title of the message.
        /// </summary>
        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        /// <summary>
        /// Date the message was sent at.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime SentAt { get; set; } = default!;

        /// <summary>
        /// Whether the message was read by the receiver.
        /// </summary>
        public bool IsRead { get; set; } = false;

        /// <summary>
        /// Id of another message a message is replying to.
        /// Can be left as null if doesn't apply.
        /// </summary>
        public Guid? ParentMessageId { get; set; }

        /// <summary>
        /// Type of the message sent depending on who sent it.
        /// </summary>
        [Required]
        [EnumDataType(typeof(MessageType))]
        public MessageType MessageType { get; set; } = default!;
    }
}
