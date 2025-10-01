using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.Message
{
    public class GetMessageDto
    {
        //Filter By fields
        public List<Guid>? SenderId { get; set; }

        public List<Guid>? ReceiverId { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? SentAtStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? SentAtEnd { get; set; }

        public bool? IsRead { get; set; }

        public List<Guid>? ParentMessageId { get; set; }

        public List<MessageType>? MessageType { get; set; }

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
