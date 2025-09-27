using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the GPU (Graphical Processing Unit) which processes tasks requiring heavy operations such as graphics on the computer.
    /// </summary>
    public class GPUComponent : BaseComponent
    {
        /// <summary>
        /// The GPU chipset (e.g., NVIDIA RTX 4090, AMD Radeon RX 7900 XTX, ARC B580).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Chipset cannot be longer than 100 characters!")]
        public string Chipset { get; set; } = default!;

        /// <summary>
        /// Amount of dedicated Video Memory (VRAM) in MB.
        /// </summary>
        [Required]
        [Range(256, 262144, ErrorMessage = "Video Memory must be between 256 MB and 262144 MB (256 GB)")]
        public int VideoMemoryAmount { get; set; } = default!;

        /// <summary>
        /// What type of Video Memory the GPU uses (e.g., GDDR6, GDDR6X, HBM2).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Video Memory type cannot be longer than 50 characters!")]
        public string VideoMemoryType { get; set; } = default!;

        /// <summary>
        /// GPU base core clock speed in MHz.
        /// </summary>
        [Required]
        [Range(100, 8000, ErrorMessage = "Core Base Clock Speed must be between 100 MHz and 8000 MHz")]
        public int CoreBaseClockSpeed { get; set; } = default!;

        /// <summary>
        /// GPU boost core clock speed in MHz.
        /// </summary>
        [Required]
        [Range(100, 8000, ErrorMessage = "Core Boost Clock Speed must be between 100 MHz and 8000 MHz")]
        public int CoreBoostClockSpeed { get; set; } = default!;

        /// <summary>
        /// Number of specialized GPU cores/shaders for task division.
        /// </summary>
        [Required]
        [Range(1, 50000, ErrorMessage = "Core count must be between 1 and 50000")]
        public int CoreCount { get; set; } = default!;

        /// <summary>
        /// Effective memory clock speed in MHz.
        /// </summary>
        [Required]
        [Range(100, 50000, ErrorMessage = "Effective Memory Clock Speed must be between 100 MHz and 50000 MHz")]
        public decimal EffectiveMemoryClockSpeed { get; set; } = default!;

        /// <summary>
        /// How much data can be transferred on a bus in bits per second.
        /// </summary>
        [Required]
        [Range(32, 4096, ErrorMessage = "Memory Bus must be between 32-bit and 4096-bit")]
        public int MemoryBusWidth { get; set; } = default!;

        /// <summary>
        /// Frame synchronization technology supported by the GPU (e.g., G-SYNC, FreeSync, None).
        /// FrameSync is a technology used 
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Frame sync value cannot be longer than 50 characters!")]
        public string FrameSync { get; set; } = default!;

        /// <summary>
        /// Length of the GPU in mm.
        /// </summary>
        [Required]
        [Range(10, 600, ErrorMessage = "GPU length must be between 10 and 600 mm")]
        public int Length { get; set; } = default!;

        /// <summary>
        /// Thermal Design Power (TDP), the maximum heat the CPU can generate in Watts.
        /// </summary>
        [Required]
        [Range(1, 2000, ErrorMessage = "Thermal design power must be between 1 and 2000 W")]
        public int ThermalDesignPower { get; set; } = default!;

        /// <summary>
        /// Number of case expansion slots the GPU occupies.
        /// </summary>
        [Required]
        [Range(1, 10, ErrorMessage = "Expansion Slot Width must be between 1 and 5")]
        public int CaseExpansionSlotWidth { get; set; } = default!;

        /// <summary>
        /// Total number of expansion slots the GPU occupies, accounting for the cooler size.
        /// </summary>
        [Required]
        [Range(1, 10, ErrorMessage = "Total Slot Width must be between 1 and 10")]
        public int TotalSlotWidth { get; set; } = default!;

        /// <summary>
        /// Type of cooling solution (e.g., 3 Fans, 2 Fans, Blower, Water Cooled).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Cooling Type cannot be longer than 50 characters!")]
        public string CoolingType { get; set; } = default!;
    }
}
