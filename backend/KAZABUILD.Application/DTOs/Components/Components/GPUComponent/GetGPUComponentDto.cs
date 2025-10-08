using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.GPUComponent
{
    public class GetGPUComponentDto : GetBaseComponentDto
    {
        public List<string>? Chipset { get; set; }

        [Range(256, 262144, ErrorMessage = "Video Memory must be between 256 MB and 262144 MB (256 GB)")]
        public decimal? VideoMemoryAmountStart { get; set; }

        [Range(256, 262144, ErrorMessage = "Video Memory must be between 256 MB and 262144 MB (256 GB)")]
        public decimal? VideoMemoryAmountEnd { get; set; }

        public List<string>? VideoMemoryType { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Base Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBaseClockSpeedStart { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Base Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBaseClockSpeedEnd { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Boost Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBoostClockSpeedStart { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Boost Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBoostClockSpeedEnd { get; set; }

        [Range(1, 50000, ErrorMessage = "Core count must be between 1 and 50000")]
        public int? CoreCountStart { get; set; }

        [Range(1, 50000, ErrorMessage = "Core count must be between 1 and 50000")]
        public int? CoreCountEnd { get; set; }

        [Range(100, 50000, ErrorMessage = "Effective Memory Clock Speed must be between 100 MHz and 50000 MHz")]
        public decimal? EffectiveMemoryClockSpeedStart { get; set; }

        [Range(100, 50000, ErrorMessage = "Effective Memory Clock Speed must be between 100 MHz and 50000 MHz")]
        public decimal? EffectiveMemoryClockSpeedEnd { get; set; }

        [Range(32, 4096, ErrorMessage = "Memory Bus must be between 32-bit and 4096-bit")]
        public int? MemoryBusWidthStart { get; set; }

        [Range(32, 4096, ErrorMessage = "Memory Bus must be between 32-bit and 4096-bit")]
        public int? MemoryBusWidthEnd { get; set; }

        public List<string>? FrameSync { get; set; }

        [Range(10, 600, ErrorMessage = "GPU length must be between 10 and 600 mm")]
        public decimal? LengthStart { get; set; }

        [Range(10, 600, ErrorMessage = "GPU length must be between 10 and 600 mm")]
        public decimal? LengthEnd { get; set; }

        [Range(1, 2000, ErrorMessage = "Thermal design power must be between 1 and 2000 W")]
        public decimal? ThermalDesignPowerStart { get; set; }

        [Range(1, 2000, ErrorMessage = "Thermal design power must be between 1 and 2000 W")]
        public decimal? ThermalDesignPowerEnd { get; set; }

        [Range(1, 10, ErrorMessage = "Expansion Slot Width must be between 1 and 5")]
        public int? CaseExpansionSlotWidthStart { get; set; }

        [Range(1, 10, ErrorMessage = "Expansion Slot Width must be between 1 and 5")]
        public int? CaseExpansionSlotWidthEnd { get; set; }

        [Range(1, 10, ErrorMessage = "Total Slot Width must be between 1 and 10")]
        public int? TotalSlotAmountStart { get; set; }

        [Range(1, 10, ErrorMessage = "Total Slot Width must be between 1 and 10")]
        public int? TotalSlotAmountEnd { get; set; }

        public List<string>? CoolingType { get; set; }
    }
}
