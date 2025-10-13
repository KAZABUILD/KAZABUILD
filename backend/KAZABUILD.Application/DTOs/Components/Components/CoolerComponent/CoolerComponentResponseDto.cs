using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Application.DTOs.Components.Components.CoolerComponent
{
    public class CoolerComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? MinFanRotationSpeed { get; set; }

        public decimal? MaxFanRotationSpeed { get; set; }

        public decimal? MinNoiseLevel { get; set; }

        public decimal? MaxNoiseLevel { get; set; }

        public decimal? Height { get; set; }

        public bool? IsWaterCooled { get; set; }

        public decimal? RadiatorSize { get; set; }

        public bool? CanOperateFanless { get; set; }

        public decimal? FanSize { get; set; }

        public int? FanQuantity { get; set; }
    }
}
