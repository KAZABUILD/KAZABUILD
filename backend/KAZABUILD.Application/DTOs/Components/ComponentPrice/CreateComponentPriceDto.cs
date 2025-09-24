using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class CreateComponentPriceDto
    {
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string SourceUrl { get; set; } = default!;

        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Vendor Name cannot be longer than 50 characters!")]
        public string VendorName { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? FetchedAt { get; set; } = default!;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 9999999.99, ErrorMessage = "Price must be between 0 and 9,999,999.99")]
        [DataType(DataType.Currency)]
        public decimal Price { get; set; } = default!;

        [Required]
        [StringLength(4, ErrorMessage = "Currency cannot be longer than 4 characters!")]
        public string Currency { get; set; } = default!;
    }
}
