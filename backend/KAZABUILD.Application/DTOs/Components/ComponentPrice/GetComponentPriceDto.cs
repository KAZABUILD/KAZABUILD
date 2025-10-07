using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class GetComponentPriceDto
    {
        //Filter By fields
        public List<Guid>? ComponentId { get; set; }

        [StringLength(50, ErrorMessage = "Vendor Name cannot be longer than 50 characters!")]
        public List<string>? VendorName { get; set; } 

        [DataType(DataType.DateTime)]
        public DateTime? FetchedAtStart { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? FetchedAtEnd { get; set; } = default!;

        [StringLength(4, ErrorMessage = "Currency cannot be longer than 4 characters!")]
        public List<string>? Currency { get; set; } = default!;

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
