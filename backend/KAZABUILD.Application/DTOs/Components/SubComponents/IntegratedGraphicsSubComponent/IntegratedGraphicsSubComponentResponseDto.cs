using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent
{
    public class IntegratedGraphicsSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? Model { get; set; }

        public int? BaseClockSpeed { get; set; }

        public int? BoostClockSpeed { get; set; }

        public int? CoreCount { get; set; }
    }
}
