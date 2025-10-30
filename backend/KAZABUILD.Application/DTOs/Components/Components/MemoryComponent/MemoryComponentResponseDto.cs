// Ignore Spelling: RGB

using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Application.DTOs.Components.Components.MemoryComponent
{
    public class MemoryComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? Speed { get; set; }

        public string? RAMType { get; set; }

        public string? FormFactor { get; set; }

        public decimal? Capacity { get; set; }

        public decimal? CASLatency { get; set; }

        public string? Timings { get; set; }

        public int? ModuleQuantity { get; set; }

        public decimal? ModuleCapacity { get; set; }

        public string? ECC { get; set; }

        public string? RegisteredType { get; set; }

        public bool? HaveHeatSpreader { get; set; }

        public bool? HaveRGB { get; set; }

        public decimal? Height { get; set; }

        public decimal? Voltage { get; set; }
    }
}
