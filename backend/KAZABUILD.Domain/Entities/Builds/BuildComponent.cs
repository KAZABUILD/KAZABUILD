using KAZABUILD.Domain.Entities.Components.Components;
using Microsoft.AspNetCore.Components;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Builds
{
    /// <summary>
    /// Model representing a Component being included in a Build.
    /// </summary>
    public class BuildComponent
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the Build the Component is used in.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Id of the Component used in the Build.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Amount of the Component used in the Build.
        /// </summary>
        [Required]
        [Range(1, 100, ErrorMessage = "Amount must be between 1 and 100!")]
        public int Quantity { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public Build? Build { get; set; } = default!;
        public BaseComponent? Component { get; set; } = default!;
    }
}
