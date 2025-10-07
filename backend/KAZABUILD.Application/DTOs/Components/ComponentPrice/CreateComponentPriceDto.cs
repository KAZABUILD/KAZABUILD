using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class CreateComponentPriceDto
    {
        /// <summary>
        /// Url of the website the price is from.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string SourceUrl { get; set; } = default!;

        /// <summary>
        /// Id of the component the price is for.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Name of the vendor that selling the component.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Vendor Name cannot be longer than 50 characters!")]
        public string VendorName { get; set; } = default!;

        /// <summary>
        /// The date when the price was fetched from the website.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? FetchedAt { get; set; } = default!;

        /// <summary>
        /// The price of the product.
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 9999999.99, ErrorMessage = "Price must be between 0 and 9,999,999.99")]
        [DataType(DataType.Currency)]
        public decimal Price { get; set; } = default!;

        /// <summary>
        /// Currency the product is being sold in.
        /// </summary>
        [Required]
        [StringLength(4, ErrorMessage = "Currency cannot be longer than 4 characters!")]
        public string Currency { get; set; } = default!;
    }
}
