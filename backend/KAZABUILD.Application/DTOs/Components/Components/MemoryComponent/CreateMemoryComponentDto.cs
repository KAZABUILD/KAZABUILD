using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MemoryComponent
{
    public class CreateMemoryComponentDto : CreateBaseComponentDto
    {
        /// <summary>
        /// Memory Speed in MHz.
        /// </summary>
        [Required]
        [Range(100, 20000, ErrorMessage = "Speed must be between 100 MHz and 20000 MHz")]
        public decimal Speed { get; set; } = default!;

        /// <summary>
        /// Which generation of the DDR (Double Data Rate) the Memory belongs to (e.g., DDR4, DDR5, LPDDR5).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "RAM Type cannot be longer than 50 characters!")]
        public string RAMType { get; set; } = default!;

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the RAM module (e.g., DIMM, SO-DIMM).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Form factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// Total Capacity of the RAM kit in MB.
        /// </summary>
        [Required]
        [Range(256, 8388608, ErrorMessage = "Capacity must be between 256 MB and 8 TB (8388608 MB)")]
        public decimal Capacity { get; set; } = default!;

        /// <summary>
        /// The delay in clock cycles between the READ command and the moment data is available (e.g., CL16).
        /// Column Address Strobe (CAS) Latency is in nanoseconds when asynchronous and in clock cycles when synchronous.
        /// </summary>
        [Required]
        [Range(0, 200, ErrorMessage = "Column Address Strobe Latency must be between 0 and 200")]
        public decimal CASLatency { get; set; } = default!;

        /// <summary>
        /// Specification of the clock latency of certain specific commands issued to RAM (e.g., 30-36-36-76).
        /// </summary>
        [StringLength(50, ErrorMessage = "Timings cannot be longer than 50 characters!")]
        public string? Timings { get; set; }

        /// <summary>
        /// Number of Memory Modules installed in the RAM.
        /// </summary>
        [Required]
        [Range(1, 16, ErrorMessage = "Module Quantity must be between 1 and 128")]
        public int ModuleQuantity { get; set; } = default!;

        /// <summary>
        /// Capacity per Module in MB.
        /// </summary>
        [Required]
        [Range(64, 524288, ErrorMessage = "Module Capacity must be between 64 MB and 512 GB")]
        public decimal ModuleCapacity { get; set; } = default!;

        /// <summary>
        /// The type of Error-Correcting Code used by the RAM (e.g., Non-ECC, ECC).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string ECC { get; set; } = default!;

        /// <summary>
        /// Whether the RAM is Registered or unbuffered (e.g., Unbuffered, Registered, Load Reduced).
        /// Registered means there is a buffer between the memory and the bus to the CPU.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Registered Type cannot be longer than 50 characters!")]
        public string RegisteredType { get; set; } = default!;

        /// <summary>
        /// Whether the RAM modules have a Heat Spreader used to dissipate excess heat.
        /// </summary>
        [Required]
        public bool HaveHeatSpreader { get; set; } = default!;

        /// <summary>
        /// Whether the RAM modules have RGB lighting.
        /// </summary>
        [Required]
        public bool HaveRGB { get; set; } = default!;

        /// <summary>
        /// The Height of the RAM module in mm.
        /// </summary>
        [Range(10, 1000, ErrorMessage = "Height must be between 10 and 65 mm")]
        public decimal? Height { get; set; }

        /// <summary>
        /// The operating Voltage of the RAM.
        /// </summary>
        [Range(0, 40, ErrorMessage = "Voltage must be between 0 and 20 V")]
        public decimal? Voltage { get; set; }
    }
}
