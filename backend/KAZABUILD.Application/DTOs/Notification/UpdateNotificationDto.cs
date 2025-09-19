using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Notification
{
    public class UpdateNotificationDto
    {
        [Required]
        [EnumDataType(typeof(NotificationType))]
        public NotificationType? NotificationType { get; set; }

        [Required]
        [MaxLength(1000, ErrorMessage = "Body cannot be longer than 50 characters!")]
        public string? Body { get; set; }

        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid Link URL!")]
        public string? LinkUrl { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? SentAt { get; set; }

        public bool? IsRead { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
