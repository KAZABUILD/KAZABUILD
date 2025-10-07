using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Model storing a price for a component from an online shop.
    /// </summary>
    public class ComponentPrice
    {
        //Component price fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Website url of the website the price is from.
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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public BaseComponent Component { get; set; } = default!;
    }
}
