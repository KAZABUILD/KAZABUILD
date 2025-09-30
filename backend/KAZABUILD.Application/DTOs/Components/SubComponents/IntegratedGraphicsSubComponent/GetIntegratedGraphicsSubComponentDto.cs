using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent
{
    public class GetIntegratedGraphicsSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Model { get; set; }

        [Range(100, 10000, ErrorMessage = "Base Clock Speed must be between 100 and 10000 MHz")]
        public int? BaseClockSpeedStart { get; set; }

        [Range(100, 10000, ErrorMessage = "Base Clock Speed must be between 100 and 10000 MHz")]
        public int? BaseClockSpeedEnd { get; set; }

        [Range(100, 10000, ErrorMessage = "Boost Clock Speed must be between 100 and 10000 MHz")]
        public int? BoostClockSpeedStart { get; set; }

        [Range(100, 10000, ErrorMessage = "Boost Clock Speed must be between 100 and 10000 MHz")]
        public int? BoostClockSpeedEnd { get; set; }

        [Range(1, 50000, ErrorMessage = "Core Count must be between 1 and 10000")]
        public int? CoreCountStart { get; set; }

        [Range(1, 50000, ErrorMessage = "Core Count must be between 1 and 10000")]
        public int? CoreCountEnd { get; set; }
    }
}
