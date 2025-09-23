using KAZABUILD.Domain.Entities.Components.SubComponents;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    public class SubComponentPart
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid MainSubComponentId { get; set; } = default!;

        [Required]
        public Guid SubComponentId { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public BaseSubComponent? MainSubComponent { get; set; } = default!;
        public BaseSubComponent? SubComponent { get; set; } = default!;
    }
}
