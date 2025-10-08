using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CPUComponent
{
    public class CPUComponentResponseDto : BaseComponentResponseDto
    {
        public string? Series { get; set; }

        public string? Microarchitecture { get; set; }

        public string? CoreFamily { get; set; }

        public string? SocketType { get; set; }

        public int? CoreTotal { get; set; }

        public int? PerformanceAmount { get; set; }

        public int? EfficiencyAmount { get; set; }

        public int? ThreadsAmount { get; set; }

        public decimal? BasePerformanceSpeed { get; set; }

        public decimal? BoostPerformanceSpeed { get; set; }

        public decimal? BaseEfficiencySpeed { get; set; }

        public decimal? BoostEfficiencySpeed { get; set; }

        public decimal? L1 { get; set; }

        public decimal? L2 { get; set; }

        public decimal? L3 { get; set; }

        public decimal? L4 { get; set; }

        public bool? IncludesCooler { get; set; }

        public string? Lithography { get; set; }

        public bool? SupportsSimultaneousMultithreading { get; set; }

        public string? MemoryType { get; set; }

        public string? PackagingType { get; set; }

        public bool? SupportsECC { get; set; }

        public decimal? ThermalDesignPower { get; set; }
    }
}
