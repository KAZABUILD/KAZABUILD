using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Model representing a variant of an component.
    /// The ComponentVariant can be multi-colored, which is stored in the ColorVariant model.
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
        public BaseComponent? Component { get; set; } = default!;

        public ICollection<ColorVariant> ColorVariants { get; set; } = [];
    }
}
