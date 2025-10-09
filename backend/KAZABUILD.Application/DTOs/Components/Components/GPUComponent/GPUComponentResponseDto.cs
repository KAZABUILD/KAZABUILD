using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.GPUComponent
{
    public class GPUComponentResponseDto : BaseComponentResponseDto
    {
        public string? Chipset { get; set; }

        public decimal? VideoMemoryAmount { get; set; }

        public string? VideoMemoryType { get; set; }

        public decimal? CoreBaseClockSpeed { get; set; }

        public decimal? CoreBoostClockSpeed { get; set; }

        public int? CoreCount { get; set; }

        public decimal? EffectiveMemoryClockSpeed { get; set; }

        public int? MemoryBusWidth { get; set; }

        public string? FrameSync { get; set; }

        public decimal? Length { get; set; }

        public decimal? ThermalDesignPower { get; set; }

        public int? CaseExpansionSlotWidth { get; set; }

        public int? TotalSlotAmount { get; set; }

        public string? CoolingType { get; set; }
    }
}
