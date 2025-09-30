using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MemoryComponent
{
    public class GetMemoryComponentDto : GetBaseComponentDto
    {
        [Range(100, 20000, ErrorMessage = "Speed must be between 100 MHz and 20000 MHz")]
        public decimal? SpeedStart { get; set; }

        [Range(100, 20000, ErrorMessage = "Speed must be between 100 MHz and 20000 MHz")]
        public decimal? SpeedEnd { get; set; }

        public List<string>? RAMType { get; set; }

        public string? FormFactor { get; set; }

        [Range(256, 8388608, ErrorMessage = "Capacity must be between 256 MB and 8 TB (8388608 MB)")]
        public decimal? CapacityStart { get; set; }

        [Range(256, 8388608, ErrorMessage = "Capacity must be between 256 MB and 8 TB (8388608 MB)")]
        public decimal? CapacityEnd { get; set; }

        [Range(0, 200, ErrorMessage = "Column Address Strobe Latency must be between 0 and 200")]
        public decimal? ColumnAddressStrobeLatencyStart { get; set; }

        [Range(0, 200, ErrorMessage = "Column Address Strobe Latency must be between 0 and 200")]
        public decimal? ColumnAddressStrobeLatencyEnd { get; set; }

        public List<string>? Timings { get; set; }

        [Range(1, 16, ErrorMessage = "Module Quantity must be between 1 and 128")]
        public int? ModuleQuantityStart { get; set; }

        [Range(1, 16, ErrorMessage = "Module Quantity must be between 1 and 128")]
        public int? ModuleQuantityEnd { get; set; }

        [Range(64, 524288, ErrorMessage = "Module Capacity must be between 64 MB and 512 GB")]
        public decimal? ModuleCapacityStart { get; set; }

        [Range(64, 524288, ErrorMessage = "Module Capacity must be between 64 MB and 512 GB")]
        public decimal? ModuleCapacityEnd { get; set; }
    }
}
