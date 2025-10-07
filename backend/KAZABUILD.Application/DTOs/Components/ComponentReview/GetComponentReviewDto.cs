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
        /// <summary>
        /// Whether the paging should be used.
        /// </summary>
        public bool Paging = false;

        /// <summary>
        /// Which page should be gotten if paging enabled.
        /// </summary>
        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int? Page { get; set; }

        /// <summary>
        /// How many objects should be in the response if paging enabled.
        /// </summary>
        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int? PageLength { get; set; }

        //Query search string
        /// <summary>
        /// Query string with words to be looked for in the search.
        /// </summary>
        public string? Query { get; set; } = "";

        //Sorting related fields
        /// <summary>
        /// By which should the return items be sorted by.
        /// </summary>
        public string? OrderBy { get; set; }

        /// <summary>
        /// Sort direction - either asc or desc.
        /// </summary>
        public string SortDirection { get; set; } = "asc";
    }
}
