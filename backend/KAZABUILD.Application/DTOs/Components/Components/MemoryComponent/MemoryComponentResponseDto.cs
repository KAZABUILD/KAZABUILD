using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MemoryComponent
{
    public class MemoryComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? Speed { get; set; }

        public string? RAMType { get; set; }

        public string? FormFactor { get; set; }

        public decimal? Capacity { get; set; }

        public decimal? ColumnAddressStrobeLatency { get; set; }

        public string? Timings { get; set; }

        public int? ModuleQuantity { get; set; }

        public decimal? ModuleCapacity { get; set; }
    }
}
