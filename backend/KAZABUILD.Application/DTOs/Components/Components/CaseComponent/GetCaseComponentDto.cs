using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseComponent
{
    public class GetCaseComponentDto : GetBaseComponentDto
    {
        public List<string>? FormFactor { get; set; }

        public bool? PowerSupplyShrouded { get; set; }

        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        public decimal? PowerSupplyAmountStart { get; set; }

        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        public decimal? PowerSupplyAmountEnd { get; set; }

        public bool? HasTransparentSidePanel { get; set; }

        public List<string>? SidePanelType { get; set; }

        [Range(10, 600, ErrorMessage = "Maximum Video Card Length must be between 10 and 600 mm")]
        public decimal? MaxVideoCardLengthStart { get; set; }

        [Range(10, 600, ErrorMessage = "Maximum Video Card Length must be between 10 and 600 mm")]
        public decimal? MaxVideoCardLengthEnd { get; set; }

        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        public decimal? MaxCPUCoolerHeightStart { get; set; }

        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        public decimal? MaxCPUCoolerHeightEnd { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int? Internal35BayAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int? Internal35BayAmountEnd { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int? Internal25BayAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int? Internal25BayAmountEnd { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External35BayAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External35BayAmountEnd { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External525BayAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External525BayAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int? ExpansionSlotAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int? ExpansionSlotAmountEnd { get; set; }

        [Range(0, 1000, ErrorMessage = "Depth must be between 0 and 1000 mm")]
        public decimal? DepthStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Height must be between 0 and 1000 mm")]
        public decimal? DepthEnd { get; set; }

        [Range(0, 1000, ErrorMessage = "Height must be between 0 and 1000 mm")]
        public decimal? HeightStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Width must be between 0 and 1000 mm")]
        public decimal? HeightEnd { get; set; }

        [Range(0, 1000, ErrorMessage = "Width must be between 0 and 1000 mm")]
        public decimal? WidthStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Depth must be between 0 and 1000 mm")]
        public decimal? WidthEnd { get; set; }

        [Range(0, 1000, ErrorMessage = "Volume must be between 0 and 1000 l")]
        public decimal? VolumeStart { get; set; }

        [Range(0, 1000, ErrorMessage = "Volume must be between 0 and 1000 l")]
        public decimal? VolumeEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        public decimal? WeightStart { get; set; } = default!;

        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        public decimal? WeightEnd { get; set; } = default!;

        public bool? SupportsRearConnectingMotherboard { get; set; } = default!;
    }
}
