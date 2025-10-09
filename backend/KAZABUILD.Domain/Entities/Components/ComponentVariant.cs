using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Model storing the connection between components and colors.
    /// Represents which color variants a component is available in.
    /// </summary>
    public class ComponentVariant
    {
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public Color? Color { get; set; } = default!;

        public BaseComponent? Component { get; set; } = default!;
    }
}
