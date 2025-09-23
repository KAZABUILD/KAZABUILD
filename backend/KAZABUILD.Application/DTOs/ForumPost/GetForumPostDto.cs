using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.ForumPost
{
    public class GetForumPostDto
    {
        //Filter By fields
        [MaxLength(50, ErrorMessage = "Topic cannot be longer than 50 characters!")]
        public string? Topic { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? PostedAtStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? PostedAtEnd { get; set; }

        public Guid? CreatorId { get; set; }

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
