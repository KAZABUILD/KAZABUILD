using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CPUComponent
{
    public class CreateCPUComponentDto : CreateBaseComponentDto
    {
        [Required]
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string Series { get; set; } = default!;

        [Required]
        [StringLength(100, ErrorMessage = "Microarchitecture cannot be longer than 100 characters!")]
        public string Microarchitecture { get; set; } = default!;

        [Required]
        [StringLength(100, ErrorMessage = "Core Family cannot be longer than 100 characters!")]
        public string CoreFamily { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Socket Type cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        [Required]
        [Range(1, 512, ErrorMessage = "Core Total must be between 1 and 512")]
        public int CoreTotal { get; set; } = default!;

        [Range(100, 512, ErrorMessage = "Performance Amount must be between 1 and 512")]
        public int? PerformanceAmount { get; set; }

        [Range(1, 512, ErrorMessage = "Efficiency Amount must be between 1 and 512")]
        public int? EfficiencyAmount { get; set; }

        [Required]
        [Range(1, 256, ErrorMessage = "Threads Amount must be between 1 and 2048")]
        public int ThreadsAmount { get; set; } = default!;

        [Range(100, 10000, ErrorMessage = "Base Performance Speed must be between 100 and 10000 MHz")]
        public decimal? BasePerformanceSpeed { get; set; }

        [Range(100, 10000, ErrorMessage = "Boost Performance Speed must be between 100 and 10000 MHz")]
        public decimal? BoostPerformanceSpeed { get; set; }

        [Range(100, 10000, ErrorMessage = "Base Efficiency Speed must be between 100 and 10000 MHz")]
        public decimal? BaseEfficiencySpeed { get; set; }

        [Range(100, 10000, ErrorMessage = "Boost Efficiency Speed must be between 100 and 10000 MHz")]
        public decimal? BoostEfficiencySpeed { get; set; }

        [Range(0, 1024, ErrorMessage = "L1 cache must be between 0 KB and 1 MB")]
        public decimal? L1 { get; set; }

        [Range(1, 5120, ErrorMessage = "L2 cache must be between 1 KB and 5 MB")]
        public decimal? L2 { get; set; }

        [Range(0.5, 16, ErrorMessage = "L3 cache must be between 0.5 and 64 MB")]
        public decimal? L3 { get; set; }

        [Range(0, 1024, ErrorMessage = "L4 cache must be between 0 and 1024 MB")]
        public decimal? L4 { get; set; }

        [Required]
        public bool IncludesCooler { get; set; } = default!;

        [Required]
        [StringLength(100, ErrorMessage = "Lithography cannot be longer than 100 characters!")]
        public string Lithography { get; set; } = default!;

        [Required]
        public bool SupportsSimultaneousMultithreading { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Memory Type cannot be longer than 50 characters!")]
        public string MemoryType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Packaging Type cannot be longer than 50 characters!")]
        public string PackagingType { get; set; } = default!;

        [Required]
        public bool SupportsErrorCorrectingCode { get; set; } = default!;

        [Required]
        [Range(1, 600, ErrorMessage = "Thermal Design Power must be between 1 and 1000 W")]
        public decimal ThermalDesignPower { get; set; } = default!;
    }
}
