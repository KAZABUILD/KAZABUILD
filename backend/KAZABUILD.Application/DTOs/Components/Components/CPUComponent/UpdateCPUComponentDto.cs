using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CPUComponent
{
    public class UpdateCPUComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// CPU series (e.g., Intel Core i9, AMD Ryzen 9).
        /// </summary>
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string? Series { get; set; }

        /// <summary>
        /// CPU processor's design architecture (e.g., Zen 4, Alder Lake, Sapphire Rapids).
        /// </summary>
        [StringLength(100, ErrorMessage = "Microarchitecture cannot be longer than 100 characters!")]
        public string? Microarchitecture { get; set; }

        /// <summary>
        /// Core Family of the CPU architecture, which shares common architecture and design features (e.g., Raptor Cove, Granite Ridge).
        /// </summary>
        [StringLength(100, ErrorMessage = "Core Family cannot be longer than 100 characters!")]
        public string? CoreFamily { get; set; }

        /// <summary>
        /// The Type of Socket the CPU uses to connect to the motherboard (e.g., LGA 1851, AM5).
        /// </summary>
        [StringLength(50, ErrorMessage = "Socket Type cannot be longer than 50 characters!")]
        public string? SocketType { get; set; }

        /// <summary>
        /// The total number of physical Cores in the CPU.
        /// </summary>
        [Range(1, 512, ErrorMessage = "Core Total must be between 1 and 512")]
        public int? CoreTotal { get; set; } = default!;

        /// <summary>
        /// The total number of Performance cores (hybrid CPUs only) in the CPU.
        /// </summary>
        [Range(0, 512, ErrorMessage = "Performance Amount must be between 0 and 512")]
        public int? PerformanceAmount { get; set; }

        /// <summary>
        /// The total number of Efficiency cores (hybrid CPUs only) in the CPU.
        /// </summary>
        [Range(0, 512, ErrorMessage = "Efficiency Amount must be between 0 and 512")]
        public int? EfficiencyAmount { get; set; }

        /// <summary>
        /// The number of logical Threads the CPU can handle.
        /// </summary>
        [Range(1, 256, ErrorMessage = "Threads Amount must be between 1 and 2048")]
        public int? ThreadsAmount { get; set; } = default!;

        /// <summary>
        /// Base clock Speed for a Performance core in MHz.
        /// </summary>
        [Range(0, 10000, ErrorMessage = "Base Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BasePerformanceSpeed { get; set; }

        /// <summary>
        /// Max boosted clock Speed for a Performance core in MHz.
        /// </summary>
        [Range(0, 10000, ErrorMessage = "Boost Performance Speed must be between 0 and 10000 MHz")]
        public decimal? BoostPerformanceSpeed { get; set; }

        /// <summary>
        /// Base clock Speed for an Efficiency core in MHz.
        /// </summary>
        [Range(0, 10000, ErrorMessage = "Base Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BaseEfficiencySpeed { get; set; }

        /// <summary>
        /// Max boosted clock Speed for an Efficiency core in MHz.
        /// </summary>
        [Range(0, 10000, ErrorMessage = "Boost Efficiency Speed must be between 0 and 10000 MHz")]
        public decimal? BoostEfficiencySpeed { get; set; }

        /// <summary>
        /// The size of the Level 1 cache in KB.
        /// </summary>
        [Range(0, 1024, ErrorMessage = "L1 cache must be between 0 KB and 1 MB")]
        public decimal? L1 { get; set; }

        /// <summary>
        /// The size of the Level 2 cache in KB.
        /// </summary>
        [Range(0, 5120, ErrorMessage = "L2 cache must be between 0 KB and 5 MB")]
        public decimal? L2 { get; set; }

        /// <summary>
        /// The size of the Level 3 cache in MB.
        /// </summary>
        [Range(0, 64, ErrorMessage = "L3 cache must be between 0 and 64 MB")]
        public decimal? L3 { get; set; }

        /// <summary>
        /// The size of the Level 4 cache in MB.
        /// </summary>
        [Range(0, 1024, ErrorMessage = "L4 cache must be between 0 and 1024 MB")]
        public decimal? L4 { get; set; }

        /// <summary>
        /// Whether the CPU includes a stock Cooler.
        /// </summary>
        public bool? IncludesCooler { get; set; }

        /// <summary>
        /// The manufacturing process technology used in the CPU (e.g., 7nm, Intel 10nm, TSMC 5nm).
        /// Can be multiple process technologies if chiplet design.
        /// </summary>
        [StringLength(100, ErrorMessage = "Lithography cannot be longer than 100 characters!")]
        public string? Lithography { get; set; }

        /// <summary>
        /// Whether the CPU Supports Simultaneous Multithreading (SMT), also known as hyperthreading.
        /// </summary>
        public bool? SupportsSimultaneousMultithreading { get; set; }

        /// <summary>
        /// Supported Memory Type (e.g., DDR4, DDR5).
        /// </summary>
        [StringLength(50, ErrorMessage = "Memory Type cannot be longer than 50 characters!")]
        public string? MemoryType { get; set; }

        /// <summary>
        /// The type of Packaging the CPU comes in (e.g., Box, Tray/OEM).
        /// </summary>
        [StringLength(50, ErrorMessage = "Packaging Type cannot be longer than 50 characters!")]
        public string? PackagingType { get; set; }

        /// <summary>
        /// Whether the CPU supports detecting and correcting errors in data transmission or storage via ECC (Error-Correcting Code) memory.
        /// </summary>
        public bool? SupportsECC { get; set; }

        /// <summary>
        /// Thermal Design Power (TDP), the maximum heat the CPU can generate in Watts.
        /// </summary>
        [Range(1, 600, ErrorMessage = "Thermal Design Power must be between 1 and 600 W")]
        public decimal? ThermalDesignPower { get; set; }
    }
}
