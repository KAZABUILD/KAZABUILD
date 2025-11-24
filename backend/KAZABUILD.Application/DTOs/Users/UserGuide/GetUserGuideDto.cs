using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserGuide
{
    public class GetUserGuideDto
    {
        //Filter By fields
        public List<string>? Title { get; set; }

        public List<string>? Author { get; set; }

        public List<string>? Category { get; set; }

        [Range(0, 1000, ErrorMessage = "Time To Read must be between 0 and 1000 min")]
        public decimal? TimeToReadStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Time To Read must be between 0 and 1000 min")]
        public decimal? TimeToReadEnd { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? PostedAtStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? PostedAtEnd { get; set; }

        //Paging related fields
        /// <summary>
        /// Whether the paging should be used.
        /// </summary>
        public bool Paging { get; set; } = false;

        /// <summary>
        /// Which page should be gotten if paging enabled.
        /// </summary>
        public int? Page { get; set; }

        /// <summary>
        /// How many objects should be in the response if paging enabled.
        /// </summary>
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
