using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentColor
{
    public class UpdateComponentColorDto
    {
        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public string? ColorName { get; set; }

        [StringLength(7, ErrorMessage = "Color Code must be a valid hex code, so no longer than 7 characters")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color Code must be a valid hex format (#RGB or #RRGGBB)")]
        public string? ColorCode { get; set; } = default!;

        public bool? IsAvailable { get; set; } = true;

        [Column(TypeName = "decimal(18,2)")]
        [Range(-9999999.99, 9999999.99, ErrorMessage = "Additional Price must be between -9,999,999.99 and 9,999,999.99")]
        [DataType(DataType.Currency)]
        public decimal? AdditionalPrice { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
