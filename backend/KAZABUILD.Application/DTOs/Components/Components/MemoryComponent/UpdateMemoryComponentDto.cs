using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MemoryComponent
{
    public class UpdateMemoryComponentDto : UpdateBaseComponentDto
    {
        [Range(100, 20000, ErrorMessage = "Speed must be between 100 MHz and 20000 MHz")]
        public decimal? Speed { get; set; }

        [StringLength(50, ErrorMessage = "RAM Type cannot be longer than 50 characters!")]
        public string? RAMType { get; set; }

        [StringLength(50, ErrorMessage = "Form factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        [Range(256, 8388608, ErrorMessage = "Capacity must be between 256 MB and 8 TB (8388608 MB)")]
        public decimal? Capacity { get; set; }

        [Range(0, 200, ErrorMessage = "Column Address Strobe Latency must be between 0 and 200")]
        public decimal? CASLatency { get; set; }

        [StringLength(50, ErrorMessage = "Timings cannot be longer than 50 characters!")]
        public string? Timings { get; set; }

        [Range(1, 16, ErrorMessage = "Module Quantity must be between 1 and 128")]
        public int? ModuleQuantity { get; set; }

        [Range(64, 524288, ErrorMessage = "Module Capacity must be between 64 MB and 512 GB")]
        public int? ModuleCapacity { get; set; }

        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string? ErrorCorrectingCode { get; set; }

        [StringLength(50, ErrorMessage = "Registered Type cannot be longer than 50 characters!")]
        public string? RegisteredType { get; set; }

        public bool? HaveHeatSpreader { get; set; }

        public bool? HaveRGB { get; set; }

        [Range(10, 1000, ErrorMessage = "Height must be between 10 and 65 mm")]
        public decimal? Height { get; set; }

        [Range(0, 40, ErrorMessage = "Voltage must be between 0 and 20 V")]
        public decimal? Voltage { get; set; }
    }
}
