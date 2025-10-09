using KAZABUILD.Domain.Entities.Components.SubComponents;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components
{
    /// <summary>
    /// Connector model for defining which subComponent is a part of another subComponent.
    /// </summary>
    public class SubComponentPart
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the main component.
        /// </summary>
        [Required]
        public Guid MainSubComponentId { get; set; } = default!;

        /// <summary>
        /// Id of the subComponent that is part of the main subComponent.
        /// </summary>
        [Required]
        public Guid SubComponentId { get; set; } = default!;

        /// <summary>
        /// How many of the subComponent is a part of the main subComponent.
        /// </summary>
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
        public BaseSubComponent? MainSubComponent { get; set; } = default!;
        public BaseSubComponent? SubComponent { get; set; } = default!;
    }
}
