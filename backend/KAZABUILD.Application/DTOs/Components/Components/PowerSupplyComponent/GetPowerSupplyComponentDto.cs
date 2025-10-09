using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent
{
    public class GetPowerSupplyComponentDto : GetBaseComponentDto
    {
        [Range(10, 5000, ErrorMessage = "Power Output must be between 10 and 5000 W")]
        public decimal? PowerOutputStart { get; set; }

        [Range(10, 5000, ErrorMessage = "Power Output must be between 10 and 5000 W")]
        public decimal? PowerOutputEnd { get; set; }

        public List<string>? FormFactor { get; set; }

        public List<string>? EfficiencyRating { get; set; }

        public List<string>? ModularityType { get; set; }

        [Range(0, 500, ErrorMessage = "Length must be between 0 and 500 mm")]
        public decimal? LengthStart { get; set; }

        [Range(0, 500, ErrorMessage = "Length must be between 0 and 500 mm")]
        public decimal? LengthEnd { get; set; }

        public bool? IsFanless { get; set; }
    }
}
