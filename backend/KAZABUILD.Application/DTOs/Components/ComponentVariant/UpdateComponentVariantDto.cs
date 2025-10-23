using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentVariant
{
    public class UpdateComponentVariantDto
    {
        /// <summary>
        /// Id of the color.
        /// </summary>
        [StringLength(7, ErrorMessage = "Color Code must be a valid hex code, so no longer than 7 characters")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color Code must be a valid hex format (#RGB or #RRGGBB)")]
        public List<string>? ColorCodes { get; set; }

        /// <summary>
        /// Whether the color variant is available in online shops.
        /// </summary>
        public bool? IsAvailable { get; set; } = true;

        /// <summary>
        /// Additional price for this color variant.
        /// Can be a discount.
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        [Range(-9999999.99, 9999999.99, ErrorMessage = "Additional Price must be between -9,999,999.99 and 9,999,999.99")]
        [DataType(DataType.Currency)]
        public decimal? AdditionalPrice { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
