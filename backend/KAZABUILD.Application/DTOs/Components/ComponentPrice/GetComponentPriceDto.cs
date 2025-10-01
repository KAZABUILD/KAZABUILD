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
