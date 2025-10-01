using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Components.SubComponents;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    public class ComponentPart
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        public Guid SubComponentId { get; set; } = default!;

        [Required]
        [Range(1, 50, ErrorMessage = "Amount must be between 1 and 50!")]
        public int Amount { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public BaseComponent? Component { get; set; } = default!;
        public BaseSubComponent? SubComponent { get; set; } = default!;
    }
}
