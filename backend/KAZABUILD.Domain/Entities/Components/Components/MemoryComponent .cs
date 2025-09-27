using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the RAM (Random Access Memory) which stores data used by application currently running on the computer.
    /// </summary>
    public class MemoryComponent : BaseComponent
    {
        /// <summary>
        /// Memory speed in MHz.
        /// </summary>
        [Required]
        [Range(100, 20000, ErrorMessage = "Speed must be between 100 MHz and 20000 MHz")]
        public int Speed { get; set; } = default!;

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
        /// Total capacity of the RAM kit in MB.
        /// </summary>
        [Required]
        [Range(256, 8388608, ErrorMessage = "Capacity must be between 256 MB and 8 TB (8388608 MB)")]
        public int Capacity { get; set; } = default!;

        /// <summary>
        /// The delay in clock cycles between the READ command and the moment data is available (e.g., CL16).
        /// Column Address Strobe (CAS) Latency is in nanoseconds when asynchronous and in clock cycles when synchronous.
        /// </summary>
        [Required]
        [Range(0, 200, ErrorMessage = "Column Address Strobe Latency must be between 0 and 200")]
        public decimal ColumnAddressStrobeLatency { get; set; } = default!;

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
        public int ModuleCapacity { get; set; } = default!;
    }
}
