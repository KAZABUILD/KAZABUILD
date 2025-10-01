using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.GPUComponent
{
    public class UpdateGPUComponentDto : UpdateBaseComponentDto
    {
        [StringLength(100, ErrorMessage = "Chipset cannot be longer than 100 characters!")]
        public string? Chipset { get; set; }

        [Range(256, 262144, ErrorMessage = "Video Memory must be between 256 MB and 262144 MB (256 GB)")]
        public decimal? VideoMemoryAmount { get; set; }

        [StringLength(50, ErrorMessage = "Video Memory type cannot be longer than 50 characters!")]
        public string? VideoMemoryType { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Base Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBaseClockSpeed { get; set; }

        [Range(100, 8000, ErrorMessage = "Core Boost Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBoostClockSpeed { get; set; }

        [Range(1, 50000, ErrorMessage = "Core count must be between 1 and 50000")]
        public int? CoreCount { get; set; }

        [Range(100, 50000, ErrorMessage = "Effective Memory Clock Speed must be between 100 MHz and 50000 MHz")]
        public decimal? EffectiveMemoryClockSpeed { get; set; }

        [Range(32, 4096, ErrorMessage = "Memory Bus must be between 32-bit and 4096-bit")]
        public int? MemoryBusWidth { get; set; }

        [StringLength(50, ErrorMessage = "Frame sync value cannot be longer than 50 characters!")]
        public string? FrameSync { get; set; }

        [Range(10, 600, ErrorMessage = "GPU length must be between 10 and 600 mm")]
        public decimal? Length { get; set; }

        [Range(1, 2000, ErrorMessage = "Thermal design power must be between 1 and 2000 W")]
        public decimal? ThermalDesignPower { get; set; }

        [Range(1, 10, ErrorMessage = "Expansion Slot Width must be between 1 and 5")]
        public int? CaseExpansionSlotWidth { get; set; }

        [Range(1, 10, ErrorMessage = "Total Slot Width must be between 1 and 10")]
        public int? TotalSlotWidth { get; set; }

        [StringLength(50, ErrorMessage = "Cooling Type cannot be longer than 50 characters!")]
        public string? CoolingType { get; set; }
    }
}
