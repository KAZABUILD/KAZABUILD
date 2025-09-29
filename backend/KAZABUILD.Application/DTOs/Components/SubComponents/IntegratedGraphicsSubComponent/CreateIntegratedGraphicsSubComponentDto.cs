using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent
{
    public class CreateIntegratedGraphicsSubComponentDto : CreateBaseSubComponentDto
    {
        [StringLength(100, ErrorMessage = "Model cannot be longer than 100 characters!")]
        public string? Model { get; set; } = default!;

        [Required]
        [Range(100, 10000, ErrorMessage = "Base Clock Speed must be between 100 and 10000 MHz")]
        public int BaseClockSpeed { get; set; } = default!;

        [Required]
        [Range(100, 10000, ErrorMessage = "Boost Clock Speed must be between 100 and 10000 MHz")]
        public int BoostClockSpeed { get; set; } = default!;

        [Required]
        [Range(1, 50000, ErrorMessage = "Core Count must be between 1 and 10000")]
        public int CoreCount { get; set; } = default!;
    }
}
