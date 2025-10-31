using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model which stores messages exchanged between users.
    /// </summary>
    public class Message
    {
        //Message fields
        [Key]
        public Guid Id { get; set; } = default!;

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
        /// Encrypted content of the message.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string CipherText { get; set; } = default!;

        /// <summary>
        /// Initialization Vector used during encryption process.
        /// </summary>
        [Required]
        public string IV { get; set; } = default!;

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
        public ICollection<UserReport> UserReports { get; set; } = [];
    }
}
