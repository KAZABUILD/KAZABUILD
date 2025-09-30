using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.StorageComponent
{
    public class GetStorageComponentDto : GetBaseComponentDto
    {
        public List<string>? Series { get; set; }

        [Range(0, 8388608, ErrorMessage = "Capacity must be between 0 and 8 PB (8388608 GB)")]
        public decimal? CapacityStart { get; set; }

        [Range(0, 8388608, ErrorMessage = "Capacity must be between 0 and 8 PB (8388608 GB)")]
        public decimal? CapacityEnd { get; set; }

        public List<string>? DriveType { get; set; }

        public List<string>? FormFactor { get; set; }

        public List<string>? Interface { get; set; }

        public bool? HasNVMe { get; set; }
    }
}
