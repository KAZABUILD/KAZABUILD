using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing Notification sent by the staff or system.
    /// Can be scheduled for the future.
    /// </summary>
    public class Notification
    {
        //Notification fields
        [Key]
        public Guid Id { get; set; } = default!;

        /// <summary>
        /// Id of the user receiving the notification.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Type of notification received.
        /// Can be used to segregate them in the inbox.
        /// </summary>
        [Required]
        [EnumDataType(typeof(NotificationType))]
        public NotificationType NotificationType { get; set; } = default!;

        /// <summary>
        /// Body of the notification.
        /// Should be stored as HTML.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Body cannot be longer than 50 characters!")]
        public string Body { get; set; } = default!;

        /// <summary>
        /// Title of the notification.
        /// </summary>
        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        /// <summary>
        /// Redirect link that will open an external website for promotional notifications. Can be nullable.
        /// </summary>
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid Link URL!")]
        public string? LinkUrl { get; set; } = default!;

        /// <summary>
        /// Date that the notification will be or was sent/received.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime SentAt { get; set; } = default!;

        /// <summary>
        /// Signifies whether the user read the notification or not.
        /// </summary>
        public bool IsRead { get; set; } = false;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
    }
}
