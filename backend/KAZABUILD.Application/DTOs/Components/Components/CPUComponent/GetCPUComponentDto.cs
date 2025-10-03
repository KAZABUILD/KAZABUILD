using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CPUComponent
{
    public class GetCPUComponentDto : GetBaseComponentDto
    {
        public List<string>? Series { get; set; }

        public List<string>? Microarchitecture { get; set; }

        public List<string>? CoreFamily { get; set; }

        public List<string>? SocketType { get; set; }

        [Range(1, 512, ErrorMessage = "Core Total must be between 1 and 512")]
        public int? CoreTotalStart { get; set; }

        [Range(1, 512, ErrorMessage = "Core Total must be between 1 and 512")]
        public int? CoreTotalEnd { get; set; }

        [Range(0, 512, ErrorMessage = "Performance Amount must be between 0 and 512")]
        public int? PerformanceAmountStart { get; set; }

        [Range(0, 512, ErrorMessage = "Performance Amount must be between 0 and 512")]
        public int? PerformanceAmountEnd { get; set; }

        [Range(0, 512, ErrorMessage = "Efficiency Amount must be between 0 and 512")]
        public int? EfficiencyAmountStart { get; set; }

        [Range(0, 512, ErrorMessage = "Efficiency Amount must be between 0 and 512")]
        public int? EfficiencyAmountEnd { get; set; }

        [Range(1, 256, ErrorMessage = "Threads Amount must be between 1 and 2048")]
        public int? ThreadsAmountStart { get; set; }

        [Range(1, 256, ErrorMessage = "Threads Amount must be between 1 and 2048")]
        public int? ThreadsAmountEnd { get; set; }

        [Range(0, 10000, ErrorMessage = "Base Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BasePerformanceSpeedStart { get; set; }

        [Range(0, 10000, ErrorMessage = "Base Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BasePerformanceSpeedEnd { get; set; }

        [Range(0, 10000, ErrorMessage = "Boost Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BoostPerformanceSpeedStart { get; set; }

        [Range(0, 10000, ErrorMessage = "Boost Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BoostPerformanceSpeedEnd { get; set; }

        [Range(0, 10000, ErrorMessage = "Base Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BaseEfficiencySpeedStart { get; set; }

        [Range(0, 10000, ErrorMessage = "Base Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BaseEfficiencySpeedEnd { get; set; }

        [Range(0, 10000, ErrorMessage = "Boost Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BoostEfficiencySpeedStart { get; set; }

        [Range(0, 10000, ErrorMessage = "Boost Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BoostEfficiencySpeedEnd { get; set; }

        [Range(0, 1024, ErrorMessage = "L1 cache must be between 0 KB and 1 MB")]
        public decimal? L1Start { get; set; }

        [Range(0, 1024, ErrorMessage = "L1 cache must be between 0 KB and 1 MB")]
        public decimal? L1End { get; set; }

        [Range(0, 5120, ErrorMessage = "L2 cache must be between 0 KB and 5 MB")]
        public decimal? L2Start { get; set; }

        [Range(0, 5120, ErrorMessage = "L2 cache must be between 0 KB and 5 MB")]
        public decimal? L2End { get; set; }

        [Range(0, 16, ErrorMessage = "L3 cache must be between 0 and 64 MB")]
        public decimal? L3Start { get; set; }

        [Range(0, 16, ErrorMessage = "L3 cache must be between 0 and 64 MB")]
        public decimal? L3End { get; set; }

        [Range(0, 1024, ErrorMessage = "L4 cache must be between 0 and 1024 MB")]
        public decimal? L4Start { get; set; }

        [Range(0, 1024, ErrorMessage = "L4 cache must be between 0 and 1024 MB")]
        public decimal? L4End { get; set; }

        public bool? IncludesCooler { get; set; }

        public List<string>? Lithography { get; set; }

        public bool? SupportsSimultaneousMultithreading { get; set; }

        public List<string>? MemoryType { get; set; }

        public List<string>? PackagingType { get; set; }

        public bool? SupportsErrorCorrectingCode { get; set; }

        [Range(1, 600, ErrorMessage = "Thermal Design Power must be between 1 and 1000 W")]
        public decimal? ThermalDesignPowerStart { get; set; }

        [Range(1, 600, ErrorMessage = "Thermal Design Power must be between 1 and 1000 W")]
        public decimal? ThermalDesignPowerEnd { get; set; }
    }
}
