using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent
{
    public class PowerSupplyComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? PowerOutput { get; set; }

        public string? FormFactor { get; set; }

        public string? EfficiencyRating { get; set; }

        public string? ModularityType { get; set; }

        public decimal? Length { get; set; }

        public bool? IsFanless { get; set; }
    }
}
