using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.StorageComponent
{
    public class UpdateStorageComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// Storage Series or model name (e.g., Samsung 980 Pro, WD Blue).
        /// </summary>
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string? Series { get; set; }

        /// <summary>
        /// Capacity of the Storage device in GB.
        /// </summary>
        [Range(0, 8388608, ErrorMessage = "Capacity must be between 0 and 8 PB (8388608 GB)")]
        public decimal? Capacity { get; set; }

        /// <summary>
        /// The Type of Storage Drive (e.g., SSD, HDD, NVMe, SSHD).
        /// </summary>
        [StringLength(50, ErrorMessage = "Type cannot be longer than 50 characters!")]
        public string? DriveType { get; set; }

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Storage device (e.g., M.2-2280, 2.5\", 3.5\").
        /// </summary>
        [StringLength(50, ErrorMessage = "Form factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        /// <summary>
        /// Interface used by the Storage drive (e.g., SATA, PCIe 4.0, NVMe).
        /// </summary>
        [StringLength(50, ErrorMessage = "Interface cannot be longer than 50 characters!")]
        public string? Interface { get; set; }

        /// <summary>
        /// Whether the Storage drive supports the NVMe protocol to capitalize on the low latency and internal parallelism of solid-state storage devices.
        /// </summary>
        public bool? HasNVMe { get; set; }
    }
}
