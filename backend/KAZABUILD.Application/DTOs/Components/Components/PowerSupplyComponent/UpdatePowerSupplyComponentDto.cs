using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent
{
    public class UpdatePowerSupplyComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// Maximum Power Output in Watts.
        /// </summary>
        [Range(10, 5000, ErrorMessage = "Power Output must be between 10 and 5000 W")]
        public decimal? PowerOutput { get; set; }

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Power Supply (e.g., ATX, SFX, TFX).
        /// </summary>
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        /// <summary>
        /// The 80 PLUS Efficiency certification level (e.g., 80+ Gold).
        /// </summary>
        [StringLength(50, ErrorMessage = "Efficiency Rating cannot be longer than 50 characters!")]
        public string? EfficiencyRating { get; set; }

        /// <summary>
        /// Modularity Type of the Power Supply cables (e.g., Full, Semi-Modular, Non-Modular).
        /// </summary>
        [StringLength(50, ErrorMessage = "Modularity Type cannot be longer than 50 characters!")]
        public string? ModularityType { get; set; }

        /// <summary>
        /// Physical Length of the Power Supply in mm.
        /// </summary>
        [Range(0, 500, ErrorMessage = "Length must be between 0 and 500 mm")]
        public decimal? Length { get; set; }

        /// <summary>
        /// Whether the Power Supply operates without a fan.
        /// </summary>
        public bool? IsFanless { get; set; } = default!;
    }
}
