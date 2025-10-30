using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent
{
    public class CaseFanComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? Size { get; set; }

        public int? Quantity { get; set; }

        public decimal? MinAirflow { get; set; }

        public decimal? MaxAirflow { get; set; }

        public decimal? MinNoiseLevel { get; set; }

        public decimal? MaxNoiseLevel { get; set; }

        public bool? PulseWidthModulation { get; set; }

        public string? LEDType { get; set; }

        public string? ConnectorType { get; set; }

        public string? ControllerType { get; set; }

        public decimal? StaticPressureAmount { get; set; }

        public string? FlowDirection { get; set; } = default!;
    }
}
