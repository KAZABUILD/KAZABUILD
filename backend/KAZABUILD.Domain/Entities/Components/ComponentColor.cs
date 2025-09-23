using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    public class ComponentColor
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        [StringLength(7, ErrorMessage = "Color Code must be a valid hex code, so no longer than 7 characters")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color Code must be a valid hex format (#RGB or #RRGGBB)")]
        public string ColorCode { get; set; } = default!;

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
