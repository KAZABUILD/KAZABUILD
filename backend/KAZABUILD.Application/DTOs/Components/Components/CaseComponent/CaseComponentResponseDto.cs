using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Domain.ValueObjects;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseComponent
{
    public class CaseComponentResponseDto : BaseComponentResponseDto
    {
        public string? FormFactor { get; set; }

        public bool? PowerSupplyShrouded { get; set; }

        public decimal? PowerSupplyAmount { get; set; }

        public bool? HasTransparentSidePanel { get; set; }

        public string? SidePanelType { get; set; }

        public decimal? MaxVideoCardLength { get; set; }

        public decimal? MaxCPUCoolerHeight { get; set; }

        public int? Internal35BayAmount { get; set; }

        public int? Internal25BayAmount { get; set; }

        public int? External35BayAmount { get; set; }

        public int? External525BayAmount { get; set; }

        public int? ExpansionSlotAmount { get; set; }

        public Dimension? Dimensions { get; set; }

        public decimal? Volume { get; set; }

        public decimal? Weight { get; set; }

        public bool? SupportsRearConnectingMotherboard { get; set; }
    }
}
