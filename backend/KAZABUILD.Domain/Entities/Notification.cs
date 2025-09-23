using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class Notification
    {
        //Notification fields
        [Key]
        public Guid Id { get; set; } = default!;

        [Required]
        public Guid UserId { get; set; } = default!;

        [Required]
        [EnumDataType(typeof(NotificationType))]
        public NotificationType NotificationType { get; set; } = default!;

        [Required]
        [MaxLength(1000, ErrorMessage = "Body cannot be longer than 50 characters!")]
        public string Body { get; set; } = default!;

        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid Link URL!")]
        public string? LinkUrl { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime SentAt { get; set; } = default!;

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
