using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Model for storing component colors.
    /// This model is for repeated use, a color should assigned to a component through a ComponentVariant.
    /// </summary>
    public class Color
    {
        /// <summary>
        /// Color Code as an id.
        /// </summary>
        [Key]
        [StringLength(7, ErrorMessage = "Color must be a valid hex code like #FFFFFF")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color must be a valid hex format (#RGB or #RRGGBB)")]
        public string ColorCode { get; set; } = default!;

        /// <summary>
        /// Name of the color.
        /// </summary>
        [Required]
        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public string ColorName { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<ColorVariant> ColorVariants { get; set; } = [];
    }
}
