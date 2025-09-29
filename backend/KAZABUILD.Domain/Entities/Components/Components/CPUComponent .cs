using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the CPU (Central Processing Unit) which processes a wide variety of tasks on the computer.
    /// </summary>
    public class CPUComponent : BaseComponent
    {
        /// <summary>
        /// CPU series (e.g., Intel Core i9, AMD Ryzen 9).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string Series { get; set; } = default!;

        /// <summary>
        /// CPU processor's design architecture (e.g., Zen 4, Alder Lake, Sapphire Rapids).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Microarchitecture cannot be longer than 100 characters!")]
        public string Microarchitecture { get; set; } = default!;

        /// <summary>
        /// Core Family of the CPU architecture, which shares common architecture and design features (e.g., Raptor Cove, Granite Ridge).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Core Family cannot be longer than 100 characters!")]
        public string CoreFamily { get; set; } = default!;

        /// <summary>
        /// The type of socket the CPU uses to connect to the motherboard (e.g., LGA 1851, AM5).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Socket Type cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        /// <summary>
        /// The total number of physical cores in the CPU.
        /// </summary>
        [Required]
        [Range(1, 512, ErrorMessage = "Core Total must be between 1 and 512")]
        public int CoreTotal { get; set; } = default!;

        /// <summary>
        /// The total number of Performance cores (hybrid CPUs only) in the CPU.
        /// </summary>
        [Range(100, 512, ErrorMessage = "Performance Amount must be between 1 and 512")]
        public int? PerformanceAmount { get; set; }

        /// <summary>
        /// The total number of Efficiency cores (hybrid CPUs only) in the CPU.
        /// </summary>
        [Range(1, 512, ErrorMessage = "Efficiency Amount must be between 1 and 512")]
        public int? EfficiencyAmount { get; set; }

        /// <summary>
        /// The number of logical threads the CPU can handle.
        /// </summary>
        [Required]
        [Range(1, 256, ErrorMessage = "Threads Amount must be between 1 and 2048")]
        public int ThreadsAmount { get; set; } = default!;

        /// <summary>
        /// Base clock Speed for a Performance core.
        /// </summary>
        [Range(100, 10000, ErrorMessage = "Base Performance Speed must be between 100 and 10000 MHz")]
        [Precision(7, 2)]
        public decimal? BasePerformanceSpeed { get; set; }

        /// <summary>
        /// Max boosted clock Speed for a Performance core.
        /// </summary>
        [Range(100, 10000, ErrorMessage = "Boost Performance Speed must be between 100 and 10000 MHz")]
        [Precision(7, 2)]
        public decimal? BoostPerformanceSpeed { get; set; }

        /// <summary>
        /// Base clock Speed for an Efficiency core..
        /// </summary>
        [Range(100, 10000, ErrorMessage = "Base Efficiency Speed must be between 100 and 10000 MHz")]
        [Precision(7, 2)]
        public decimal? BaseEfficiencySpeed { get; set; }

        /// <summary>
        /// Max boosted clock Speed for an Efficiency core.
        /// </summary>
        [Range(100, 10000, ErrorMessage = "Boost Efficiency Speed must be between 100 and 10000 MHz")]
        [Precision(7, 2)]
        public decimal? BoostEfficiencySpeed { get; set; }

        /// <summary>
        /// The size of the Level 1 cache in KB.
        /// </summary>
        [Range(0, 1024, ErrorMessage = "L1 cache must be between 0 KB and 1 MB")]
        [Precision(10, 6)]
        public decimal? L1 { get; set; }

        /// <summary>
        /// The size of the Level 2 cache in KB.
        /// </summary>
        [Range(1, 5120, ErrorMessage = "L2 cache must be between 1 KB and 5 MB")]
        [Precision(10, 6)]
        public decimal? L2 { get; set; }

        /// <summary>
        /// The size of the Level 3 cache in MB.
        /// </summary>
        [Range(0.5, 16, ErrorMessage = "L3 cache must be between 0.5 and 64 MB")]
        [Precision(8, 6)]
        public decimal? L3 { get; set; }

        /// <summary>
        /// The size of the Level 4 cache in MB.
        /// </summary>
        [Range(0, 1024, ErrorMessage = "L4 cache must be between 0 and 1024 MB")]
        [Precision(10, 6)]
        public decimal? L4 { get; set; }

        /// <summary>
        /// Whether the CPU includes a stock cooler.
        /// </summary>
        [Required]
        public bool IncludesCooler { get; set; } = default!;

        /// <summary>
        /// The manufacturing process technology used in the CPU (e.g., 7nm, Intel 10nm, TSMC 5nm).
        /// Can be multiple process technologies if chiplet design.
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Lithography cannot be longer than 100 characters!")]
        public string Lithography { get; set; } = default!;

        /// <summary>
        /// Whether the CPU supports simultaneous multithreading (SMT), also known as hyperthreading.
        /// </summary>
        [Required]
        public bool SupportsSimultaneousMultithreading { get; set; } = default!;

        /// <summary>
        /// Supported memory type (e.g., DDR4, DDR5).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Memory Type cannot be longer than 50 characters!")]
        public string MemoryType { get; set; } = default!;

        /// <summary>
        /// The type of packaging the CPU comes in (e.g., Box, Tray/OEM).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Packaging Type cannot be longer than 50 characters!")]
        public string PackagingType { get; set; } = default!;

        /// <summary>
        /// Whether the CPU supports detecting and correcting errors in data transmission or storage via ECC (Error-Correcting Code) memory.
        /// </summary>
        [Required]
        public bool SupportsErrorCorrectingCode { get; set; } = default!;

        /// <summary>
        /// Thermal Design Power (TDP), the maximum heat the CPU can generate in Watts.
        /// </summary>
        [Required]
        [Range(1, 600, ErrorMessage = "Thermal Design Power must be between 1 and 1000 W")]
        [Precision(6, 2)]
        public decimal ThermalDesignPower { get; set; } = default!;
    }
}
