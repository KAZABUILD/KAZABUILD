using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.Notification
{
    public class UpdateNotificationDto
    {
        /// <summary>
        /// Type of notification received.
        /// Can be used to segregate them in the inbox.
        /// </summary>
        [EnumDataType(typeof(NotificationType))]
        public NotificationType? NotificationType { get; set; }

        /// <summary>
        /// Body of the notification.
        /// Should be stored as HTML.
        /// </summary>
        [MaxLength(1000, ErrorMessage = "Body cannot be longer than 50 characters!")]
        public string? Body { get; set; }

        /// <summary>
        /// Title of the notification.
        /// </summary>
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        /// <summary>
        /// Redirect link that will open an external website for promotional notifications. Can be nullable.
        /// </summary>
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid Link URL!")]
        public string? LinkUrl { get; set; }

        /// <summary>
        /// Date that the notification will be or was sent/received.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? SentAt { get; set; }

        /// <summary>
        /// Signifies whether the user read the notification or not.
        /// </summary>
        public bool? IsRead { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
