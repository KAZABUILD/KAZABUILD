using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Case Fan which is a general cooler present within the case. Required for the computer not to overheat and break.
    /// </summary>
    public class CaseFanComponent : BaseComponent
    {
        // <summary>
        /// The size of the fan in mm.
        /// </summary>
        [Required]
        [Range(20, 500, ErrorMessage = "Fan size must be between 20 mm and 500 mm")]
        [Precision(5, 2)]
        public decimal Size { get; set; } = default!;

        /// <summary>
        /// The number of fans included.
        /// </summary>
        [Required]
        [Range(1, 20, ErrorMessage = "Quantity must be between 1 and 20")]
        public int Quantity { get; set; } = default!;

        /// <summary>
        /// Minimum airflow in CMM (Cubic Meters per Minute).
        /// </summary>
        [Required]
        [Range(0, 30, ErrorMessage = "Minimum airflow must be between 0 and 30 CMM")]
        [Precision(4, 2)]
        public decimal MinAirflow { get; set; } = default!;

        /// <summary>
        /// Maximum airflow in CMM (Cubic Meters per Minute).
        /// Leave as null if a constant and just fill in the Min Air flow.
        /// </summary>
        [Range(0, 30, ErrorMessage = "Maximum airflow must be between 0 and 30 CMM")]
        [Precision(4, 2)]
        public decimal? MaxAirflow { get; set; }

        /// <summary>
        /// Minimum noise level in dBA.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Minimum noise level must be between 0 and 100 dB")]
        [Precision(6, 3)]
        public decimal MinNoiseLevel { get; set; } = default!;

        /// <summary>
        /// Maximum noise level in dBA.
        /// Leave as null if a constant and just fill in the Min Noise Level.
        /// </summary>
        [Range(0, 100, ErrorMessage = "Maximum noise level must be between 0 and 100 dB")]
        [Precision(6, 3)]
        public decimal? MaxNoiseLevel { get; set; }

        /// <summary>
        /// Whether the fan supports Pulse Width Modulation for speed control.
        /// </summary>
        [Required]
        public bool PulseWidthModulation { get; set; } = default!;

        /// <summary>
        /// What type of LED type, if any, is in the Fan (e.g., RGB, ARGB, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "LED type cannot be longer than 50 characters!")]
        public string? LEDType { get; set; }

        /// <summary>
        /// What Connector type, if any, the fan uses (e.g., 3-pin, 4-pin).
        /// </summary>
        [StringLength(50, ErrorMessage = "Connector Type cannot be longer than 50 characters!")]
        public string? ConnectorType { get; set; }

        /// <summary>
        /// What type of Controller, if any, does the fan include (e.g., Motherboard, External Hub, Remote, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "Controller type cannot be longer than 50 characters!")]
        public string? ControllerType { get; set; }

        /// <summary>
        /// Static pressure in mmH2O (Millimetre of Water Column).
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "Static pressure must be between 0 and 20 mmH2O")]
        [Precision(6, 4)]
        public decimal StaticPressureAmount { get; set; } = default!;

        /// <summary>
        /// The direction of the airflow (e.g., Standard, Reverse).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Flow Direction cannot be longer than 50 characters!")]
        public string FlowDirection { get; set; } = default!;
    }
}
