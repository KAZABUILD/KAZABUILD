using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// Represents an Integrated Graphics Card attached to a CPU.
    /// </summary>
    public class IntegratedGraphicsSubComponent : BaseSubComponent
    {
        /// <summary>
        /// The model of the Integrated Graphics Card.
        /// If none leave as null.
        /// </summary>
        [StringLength(100, ErrorMessage = "Model cannot be longer than 100 characters!")]
        public string? Model { get; set; } = default!;

        /// <summary>
        /// Base clock speed of Integrated Graphics Card in MHz.
        /// </summary>
        [Required]
        [Range(100, 10000, ErrorMessage = "Base Clock Speed must be between 100 and 10000 MHz")]
        public int BaseClockSpeed { get; set; } = default!;

        /// <summary>
        /// Maximum boosted clock speed of the Integrated Graphics Card in MHz.
        /// </summary>
        [Required]
        [Range(100, 10000, ErrorMessage = "Boost Clock Speed must be between 100 and 10000 MHz")]
        public int BoostClockSpeed { get; set; } = default!;

        /// <summary>
        /// Number of cores/shaders in an Integrated Graphics Card.
        /// </summary>
        [Required]
        [Range(1, 50000, ErrorMessage = "Core Count must be between 1 and 10000")]
        public int CoreCount { get; set; } = default!;
    }
}
