using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    public class ComponentCompatibility
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        public Guid CompatibleComponentId { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public BaseComponent? Component { get; set; } = default!;
        public BaseComponent? CompatibleComponent { get; set; } = default!;
    }
}
