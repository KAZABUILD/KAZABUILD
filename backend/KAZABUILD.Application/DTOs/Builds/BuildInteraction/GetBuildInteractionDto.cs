using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildInteraction
{
    public class GetBuildInteractionDto
    {
        //Filter By fields
        public List<Guid>? UserId { get; set; }

        public List<Guid>? BuildId { get; set; }

        public bool? IsWishlisted { get; set; }

        public bool? IsLiked { get; set; }

        [Range(0, 100, ErrorMessage = "Amount must be between 0 and 100!")]
        public int? RatingStart { get; set; }

        [Range(0, 100, ErrorMessage = "Amount must be between 0 and 100!")]
        public int? RatingEnd { get; set; }

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
