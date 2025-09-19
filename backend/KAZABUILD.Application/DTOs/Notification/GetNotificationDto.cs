using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Notification
{
    public class GetNotificationDto
    {
        //Filter By fields
        public Guid? UserId { get; set; }

        [EnumDataType(typeof(NotificationType))]
        public NotificationType? NotificationType { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? SentAtStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? SentAtEnd { get; set; }

        public bool? IsRead { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Paging related fields
        public bool Paging = false;

        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int? Page { get; set; }

        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int? PageLength { get; set; }

        //Query search string
        public string? Query { get; set; } = "";

        //Sorting related fields
        public string? OrderBy { get; set; }

        public string SortDirection { get; set; } = "asc";
    }
}
