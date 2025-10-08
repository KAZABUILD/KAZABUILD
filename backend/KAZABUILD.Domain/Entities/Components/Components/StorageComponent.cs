using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents storage inside a computer. Used to store and retrieve data.
    /// </summary>
    public class StorageComponent : BaseComponent
    {
        /// <summary>
        /// Storage Series or model name (e.g., Samsung 980 Pro, WD Blue).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string Series { get; set; } = default!;

        /// <summary>
        /// Capacity of the Storage device in GB.
        /// </summary>
        [Required]
        [Range(0, 8388608, ErrorMessage = "Capacity must be between 0 and 8 PB (8388608 GB)")]
        [Precision(13, 6)]
        public decimal Capacity { get; set; } = default!;

        /// <summary>
        /// The Type of Storage Drive (e.g., SSD, HDD, NVMe, SSHD).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Type cannot be longer than 50 characters!")]
        public string DriveType { get; set; } = default!;

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Storage device (e.g., M.2-2280, 2.5\", 3.5\").
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Form factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// Interface used by the Storage drive (e.g., SATA, PCIe 4.0, NVMe).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Interface cannot be longer than 50 characters!")]
        public string Interface { get; set; } = default!;

        /// <summary>
        /// Whether the Storage drive supports the NVMe protocol to capitalize on the low latency and internal parallelism of solid-state storage devices.
        /// </summary>
        [Required]
        public bool HasNVMe { get; set; } = default!;
    }
}
