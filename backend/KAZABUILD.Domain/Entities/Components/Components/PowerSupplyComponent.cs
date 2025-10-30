using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the PSU (Power Supply) inside a computer, which delivers power necessary for it to function.
    /// </summary>
    public class PowerSupplyComponent : BaseComponent
    {
        /// <summary>
        /// Maximum Power Output in Watts.
        /// </summary>
        [Required]
        [Range(10, 5000, ErrorMessage = "Power Output must be between 10 and 5000 W")]
        [Precision(6, 2)]
        public decimal PowerOutput { get; set; } = default!;

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Power Supply (e.g., ATX, SFX, TFX).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// The 80 PLUS Efficiency certification level (e.g., 80+ Gold).
        /// </summary>
        [StringLength(50, ErrorMessage = "Efficiency Rating cannot be longer than 50 characters!")]
        public string? EfficiencyRating { get; set; }

        /// <summary>
        /// Modularity Type of the Power Supply cables (e.g., Full, Semi-Modular, Non-Modular).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Modularity Type cannot be longer than 50 characters!")]
        public string ModularityType { get; set; } = default!;

        /// <summary>
        /// Physical Length of the Power Supply in mm.
        /// </summary>
        [Required]
        [Range(0, 500, ErrorMessage = "Length must be between 0 and 500 mm")]
        [Precision(5, 2)]
        public decimal Length { get; set; } = default!;

        /// <summary>
        /// Whether the Power Supply operates without a fan.
        /// </summary>
        [Required]
        public bool IsFanless { get; set; } = default!;
    }
}
