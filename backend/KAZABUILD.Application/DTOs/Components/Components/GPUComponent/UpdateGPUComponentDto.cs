using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.GPUComponent
{
    public class UpdateGPUComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// The GPU chipset (e.g., NVIDIA RTX 4090, AMD Radeon RX 7900 XTX, ARC B580).
        /// </summary>
        [StringLength(100, ErrorMessage = "Chipset cannot be longer than 100 characters!")]
        public string? Chipset { get; set; }

        /// <summary>
        /// Amount of dedicated Video Memory (VRAM) in MB.
        /// </summary>
        [Range(256, 262144, ErrorMessage = "Video Memory must be between 256 MB and 262144 MB (256 GB)")]
        public decimal? VideoMemoryAmount { get; set; }

        /// <summary>
        /// What type of Video Memory the GPU uses (e.g., GDDR6, GDDR6X, HBM2).
        /// </summary>
        [StringLength(50, ErrorMessage = "Video Memory type cannot be longer than 50 characters!")]
        public string? VideoMemoryType { get; set; }

        /// <summary>
        /// GPU base core clock speed in MHz.
        /// </summary>
        [Range(100, 8000, ErrorMessage = "Core Base Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBaseClockSpeed { get; set; }

        /// <summary>
        /// GPU boost core clock speed in MHz.
        /// </summary>
        [Range(100, 8000, ErrorMessage = "Core Boost Clock Speed must be between 100 MHz and 8000 MHz")]
        public decimal? CoreBoostClockSpeed { get; set; }

        /// <summary>
        /// Number of specialized GPU cores/shaders for task division.
        /// </summary>
        [Range(1, 50000, ErrorMessage = "Core count must be between 1 and 50000")]
        public int? CoreCount { get; set; }

        /// <summary>
        /// Effective memory clock speed in MHz.
        /// </summary>
        [Range(100, 50000, ErrorMessage = "Effective Memory Clock Speed must be between 100 MHz and 50000 MHz")]
        public decimal? EffectiveMemoryClockSpeed { get; set; }

        /// <summary>
        /// How much data can be transferred on a bus in bits per second.
        /// </summary>
        [Range(32, 4096, ErrorMessage = "Memory Bus must be between 32-bit and 4096-bit")]
        public int? MemoryBusWidth { get; set; }

        /// <summary>
        /// Frame synchronization technology supported by the GPU (e.g., G-SYNC, FreeSync, None).
        /// FrameSync is a technology used 
        /// </summary>
        [StringLength(50, ErrorMessage = "Frame sync value cannot be longer than 50 characters!")]
        public string? FrameSync { get; set; }

        /// <summary>
        /// Length of the GPU in mm.
        /// </summary>
        [Range(10, 600, ErrorMessage = "GPU length must be between 10 and 600 mm")]
        public decimal? Length { get; set; }

        /// <summary>
        /// Thermal Design Power (TDP), the maximum heat the CPU can generate in Watts.
        /// </summary>
        [Range(1, 2000, ErrorMessage = "Thermal design power must be between 1 and 2000 W")]
        public decimal? ThermalDesignPower { get; set; }

        /// <summary>
        /// Number of case expansion slots the GPU occupies.
        /// </summary>
        [Range(1, 10, ErrorMessage = "Expansion Slot Width must be between 1 and 5")]
        public int? CaseExpansionSlotWidth { get; set; }

        /// <summary>
        /// Total number of expansion slots the GPU occupies, accounting for the cooler size.
        /// </summary>
        [Range(1, 10, ErrorMessage = "Total Slot Width must be between 1 and 10")]
        public int? TotalSlotWidth { get; set; }

        /// <summary>
        /// Type of cooling solution (e.g., 3 Fans, 2 Fans, Blower, Water Cooled).
        /// </summary>
        [StringLength(50, ErrorMessage = "Cooling Type cannot be longer than 50 characters!")]
        public string? CoolingType { get; set; }
    }
}
