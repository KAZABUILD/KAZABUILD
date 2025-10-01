using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent
{
    public class UpdatePowerSupplyComponentDto : UpdateBaseComponentDto
    {
        [Range(10, 5000, ErrorMessage = "Power Output must be between 10 and 5000 W")]
        public decimal? PowerOutput { get; set; }

        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        [StringLength(50, ErrorMessage = "Efficiency Rating cannot be longer than 50 characters!")]
        public string? EfficiencyRating { get; set; }

        [StringLength(50, ErrorMessage = "Modularity Type cannot be longer than 50 characters!")]
        public string? ModularityType { get; set; }

        [Range(0, 500, ErrorMessage = "Length must be between 0 and 500 mm")]
        public decimal? Length { get; set; }

        public bool? IsFanless { get; set; } = default!;
    }
}
