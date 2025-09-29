using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent
{
    public class CreateCaseFanComponentDto : CreateBaseComponentDto
    {
        [Required]
        [Range(20, 500, ErrorMessage = "Fan size must be between 20 mm and 500 mm")]
        public decimal Size { get; set; } = default!;

        [Required]
        [Range(1, 20, ErrorMessage = "Quantity must be between 1 and 20")]
        public int Quantity { get; set; } = default!;

        [Required]
        [Range(0, 30, ErrorMessage = "Minimum airflow must be between 0 and 30 CMM")]
        public decimal MinAirflow { get; set; } = default!;

        [Range(0, 30, ErrorMessage = "Maximum airflow must be between 0 and 30 CMM")]
        public decimal? MaxAirflow { get; set; }

        [Required]
        [Range(0, 100, ErrorMessage = "Minimum noise level must be between 0 and 100 dB")]
        public int MinNoiseLevel { get; set; } = default!;

        [Range(0, 100, ErrorMessage = "Maximum noise level must be between 0 and 100 dB")]
        public int? MaxNoiseLevel { get; set; }

        [Required]
        public bool PulseWidthModulation { get; set; } = default!;

        [StringLength(50, ErrorMessage = "LED type cannot be longer than 50 characters!")]
        public string? LEDType { get; set; }

        [StringLength(50, ErrorMessage = "Connector Type cannot be longer than 50 characters!")]
        public string? ConnectorType { get; set; }

        [StringLength(50, ErrorMessage = "Controller type cannot be longer than 50 characters!")]
        public string? ControllerType { get; set; }

        [Required]
        [Range(0, 20, ErrorMessage = "Static pressure must be between 0 and 20 mmH2O")]
        public decimal StaticPressureAmount { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Flow Direction cannot be longer than 50 characters!")]
        public string FlowDirection { get; set; } = default!;
    }
}
