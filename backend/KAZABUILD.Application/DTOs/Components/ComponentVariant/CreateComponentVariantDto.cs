using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentVariant
{
    public class CreateComponentVariantDto
    {
        /// <summary>
        /// Id of the component the color is for.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Id of the color.
        /// </summary>
        [Required]
        [StringLength(7, ErrorMessage = "Color Code must be a valid hex code, so no longer than 7 characters")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color Code must be a valid hex format (#RGB or #RRGGBB)")]
        public string ColorCode { get; set; } = default!;

        /// <summary>
        /// Name of the color.
        /// Modifies the Color table instead of the variant.
        /// </summary>
        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public string? ColorName { get; set; } = default!;

        /// <summary>
        /// Whether the color variant is available in online shops.
        /// </summary>
        [Required]
        public bool IsAvailable { get; set; } = true;

        /// <summary>
        /// Additional price for this color variant.
        /// Can be a discount.
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        [Range(-9999999.99, 9999999.99, ErrorMessage = "Additional Price must be between -9,999,999.99 and 9,999,999.99")]
        [DataType(DataType.Currency)]
        public decimal? AdditionalPrice { get; set; }
    }
}
