using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.Message
{
    public class UpdateMessageDto
    {
        /// <summary>
        /// Text content of the message.
        /// </summary>
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string? Content { get; set; }

        /// <summary>
        /// Title of the message.
        /// </summary>
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        /// <summary>
        /// Date the message was sent at.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? SentAt { get; set; }

        /// <summary>
        /// Whether the message was read by the receiver.
        /// </summary>
        public bool? IsRead { get; set; } = false;

        /// <summary>
        /// Id of another message a message is replying to.
        /// Can be left as null if doesn't apply.
        /// </summary>
        public Guid? ParentMessageId { get; set; }

        /// <summary>
        /// Type of the message sent depending on who sent it.
        /// </summary>
        [EnumDataType(typeof(MessageType))]
        public MessageType? MessageType { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
