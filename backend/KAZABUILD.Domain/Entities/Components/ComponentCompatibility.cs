using KAZABUILD.Domain.Entities.Components.Components;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Model defining a connection between a components if they are compatible to each other.
    /// </summary>
    public class ComponentCompatibility
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of a component to set compatibility for.s
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Id of a component compatible to the other one.
        /// </summary>
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
