using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentReview
{
    public class GetComponentReviewDto
    {
        //Filter By fields
        public List<string>? ReviewerName { get; set; } = default!;

        public List<Guid>? ComponentId { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? FetchedAtStart { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? FetchedAtEnd { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? CreatedAtStart { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? CreatedAtEnd { get; set; } = default!;

        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal? RatingStart { get; set; } = default!;

        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal? RatingEnd { get; set; } = default!;

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
