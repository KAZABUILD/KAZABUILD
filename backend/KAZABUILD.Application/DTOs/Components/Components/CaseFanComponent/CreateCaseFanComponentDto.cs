using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent
{
    public class CreateCaseFanComponentDto : CreateBaseComponentDto
    {
        /// <summary>
        /// The size of the Fan in mm.
        /// </summary>
        [Required]
        [Range(20, 500, ErrorMessage = "Fan size must be between 20 mm and 500 mm")]
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
        public decimal MinAirflow { get; set; } = default!;

        /// <summary>
        /// Maximum airflow in CMM (Cubic Meters per Minute).
        /// Leave as null if a constant and just fill in the Min Air flow.
        /// </summary>
        [Range(0, 30, ErrorMessage = "Maximum airflow must be between 0 and 30 CMM")]
        public decimal? MaxAirflow { get; set; }

        /// <summary>
        /// Minimum noise level in dBA.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Minimum noise level must be between 0 and 100 dB")]
        public decimal MinNoiseLevel { get; set; } = default!;

        /// <summary>
        /// Maximum noise level in dBA.
        /// Leave as null if a constant and just fill in the Min Noise Level.
        /// </summary>
        [Range(0, 100, ErrorMessage = "Maximum noise level must be between 0 and 100 dB")]
        public decimal? MaxNoiseLevel { get; set; }

        /// <summary>
        /// Whether the Fan supports Pulse Width Modulation for speed control.
        /// </summary>
        [Required]
        public bool PulseWidthModulation { get; set; } = default!;

        /// <summary>
        /// What type of LED type, if any, is in the Fan (e.g., RGB, ARGB, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "LED type cannot be longer than 50 characters!")]
        public string? LEDType { get; set; }

        /// <summary>
        /// What Connector type, if any, the Fan uses (e.g., 3-pin, 4-pin).
        /// </summary>
        [StringLength(50, ErrorMessage = "Connector Type cannot be longer than 50 characters!")]
        public string? ConnectorType { get; set; }

        /// <summary>
        /// What type of Controller, if any, does the Fan include (e.g., Motherboard, External Hub, Remote, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "Controller type cannot be longer than 50 characters!")]
        public string? ControllerType { get; set; }

        /// <summary>
        /// Static pressure in mmH2O (Millimetre of Water Column).
        /// Measures how much power the Fan can exert to move air.
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "Static pressure must be between 0 and 20 mmH2O")]
        public decimal StaticPressureAmount { get; set; } = default!;

        /// <summary>
        /// The direction of the airflow (e.g., Standard, Reverse).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Flow Direction cannot be longer than 50 characters!")]
        public string FlowDirection { get; set; } = default!;
    }
}
