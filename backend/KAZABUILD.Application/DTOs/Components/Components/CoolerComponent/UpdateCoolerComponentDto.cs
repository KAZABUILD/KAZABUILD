using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CoolerComponent
{
    public class UpdateCoolerComponentDto : UpdateBaseComponentDto
    {
        [Range(0, 6000, ErrorMessage = "Minimum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MinFanRotationSpeed { get; set; }

        [Range(0, 6000, ErrorMessage = "Maximum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MaxFanRotationSpeed { get; set; }

        [Range(0, 100, ErrorMessage = "Minimum Noise Level must be between 0 and 100 dB")]
        public decimal? MinNoiseLevel { get; set; }

        [Range(0, 100, ErrorMessage = "Maximum Noise Level must be between 0 and 100 dB")]
        public decimal? MaxNoiseLevel { get; set; }

        [Range(0, 400, ErrorMessage = "Height must be between 0 and 400 mm")]
        public decimal? Height { get; set; }

        public bool? IsWaterCooled { get; set; }

        [Range(0, 1000, ErrorMessage = "Radiator Size must be between 0 and 1000 mm")]
        public decimal? RadiatorSize { get; set; }

        public bool? CanOperateFanless { get; set; }

        [Range(40, 500, ErrorMessage = "Fan Size must be between 10 and 500 mm")]
        public decimal? FanSize { get; set; }

        [Range(0, 10, ErrorMessage = "Fan Quantity must be between 0 and 10")]
        public int? FanQuantity { get; set; }
    }
}
