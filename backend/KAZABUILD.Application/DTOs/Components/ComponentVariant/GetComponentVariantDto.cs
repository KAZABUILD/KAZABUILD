using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentVariant
{
    public class GetComponentVariantDto
    {
        //Filter by fields
        public List<Guid>? ComponentId { get; set; }

        [StringLength(7, ErrorMessage = "Color Code must be a valid hex code, so no longer than 7 characters")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color Code must be a valid hex format (#RGB or #RRGGBB)")]
        public List<string>? ColorCode { get; set; }

        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public List<string>? ColorName { get; set; }

        public bool? IsAvailable { get; set; }

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
