using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CoolerComponent
{
    public class GetCoolerComponentDto : GetBaseComponentDto
    {
        [Range(0, 6000, ErrorMessage = "Minimum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MinFanRotationSpeedStart { get; set; }

        [Range(0, 6000, ErrorMessage = "Minimum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MinFanRotationSpeedEnd { get; set; }

        [Range(0, 6000, ErrorMessage = "Maximum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MaxFanRotationSpeedStart { get; set; }

        [Range(0, 6000, ErrorMessage = "Maximum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public decimal? MaxFanRotationSpeedEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Minimum Noise Level must be between 0 and 100 dB")]
        public decimal? MinNoiseLevelStart { get; set; }

        [Range(0, 100, ErrorMessage = "Minimum Noise Level must be between 0 and 100 dB")]
        public decimal? MinNoiseLevelEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Maximum Noise Level must be between 0 and 100 dB")]
        public decimal? MaxNoiseLevelStart { get; set; }

        [Range(0, 100, ErrorMessage = "Maximum Noise Level must be between 0 and 100 dB")]
        public decimal? MaxNoiseLevelEnd { get; set; }

        [Range(0, 400, ErrorMessage = "Height must be between 0 and 400 mm")]
        public decimal? HeightStart { get; set; }

        [Range(0, 400, ErrorMessage = "Height must be between 0 and 400 mm")]
        public decimal? HeightEnd { get; set; }

        public bool? IsWaterCooled { get; set; }

        [Range(0, 1000, ErrorMessage = "Radiator Size must be between 0 and 1000 mm")]
        public decimal? RadiatorSizeStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Radiator Size must be between 0 and 1000 mm")]
        public decimal? RadiatorSizeEnd { get; set; }

        public bool? CanOperateFanless { get; set; }

        [Range(40, 500, ErrorMessage = "Fan Size must be between 10 and 500 mm")]
        public decimal? FanSizeStart { get; set; }

        [Range(40, 500, ErrorMessage = "Fan Size must be between 10 and 500 mm")]
        public decimal? FanSizeEnd { get; set; }

        [Range(0, 10, ErrorMessage = "Fan Quantity must be between 0 and 10")]
        public int? FanQuantityStart { get; set; }

        [Range(0, 10, ErrorMessage = "Fan Quantity must be between 0 and 10")]
        public int? FanQuantityEnd { get; set; }
    }
}
