using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.UserFollow
{
    public class GetUserFollowDto
    {
        //Filter By fields
        public Guid? FollowerId { get; set; }

        public Guid? FollowedId { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? FollowedAtStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? FollowedAtEnd { get; set; }

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
