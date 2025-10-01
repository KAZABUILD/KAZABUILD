using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Domain.ValueObjects;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseComponent
{
    public class UpdateCaseComponentDto : UpdateBaseComponentDto
    {
        [StringLength(100, ErrorMessage = "Form Factor cannot be longer than 100 characters!")]
        public string? FormFactor { get; set; }

        public bool? PowerSupplyShrouded { get; set; }

        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        public decimal? PowerSupplyAmount { get; set; }

        public bool? HasTransparentSidePanel { get; set; }

        [StringLength(50, ErrorMessage = "Side Panel Type cannot be longer than 50 characters!")]
        public string? SidePanelType { get; set; }

        [Range(10, 600, ErrorMessage = "Maximum Video Card Length must be between 10 and 600 mm")]
        public decimal? MaxVideoCardLength { get; set; }

        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        public decimal? MaxCPUCoolerHeight { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int? Internal35BayAmount { get; set; }

        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int? Internal25BayAmount { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External35BayAmount { get; set; }

        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External525BayAmount { get; set; }

        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int? ExpansionSlotAmount { get; set; }

        public Dimension? Dimensions { get; set; }

        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        public decimal? Weight { get; set; }

        public bool? SupportsRearConnectingMotherboard { get; set; }
    }
}
