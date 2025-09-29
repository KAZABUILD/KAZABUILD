using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Domain.ValueObjects;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseComponent
{
    public class CreateCaseComponentDto : CreateBaseComponentDto
    {
        [Required]
        [StringLength(100, ErrorMessage = "Form Factor cannot be longer than 100 characters!")]
        public string FormFactor { get; set; } = default!;

        [Required]
        public bool PowerSupplyShrouded { get; set; } = default!;

        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        public decimal? PowerSupplyAmount { get; set; }

        [Required]
        public bool HasTransparentSidePanel { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Side Panel Type cannot be longer than 50 characters!")]
        public string? SidePanelType { get; set; }

        [Required]
        [Range(10, 600, ErrorMessage = "Maximum Video Card Length must be between 10 and 600 mm")]
        public decimal MaxVideoCardLength { get; set; } = default!;

        [Required]
        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        public decimal MaxCPUCoolerHeight { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int Internal35BayAmount { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int Internal25BayAmount { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int External35BayAmount { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int External525BayAmount { get; set; } = default!;

        [Required]
        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int ExpansionSlotAmount { get; set; } = default!;

        [Required]
        public Dimension Dimensions { get; set; } = default!;

        public decimal Volume => Dimensions.Height * Dimensions.Width * Dimensions.Depth;

        [Required]
        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        public decimal Weight { get; set; } = default!;

        [Required]
        public bool SupportsRearConnectingMotherboard { get; set; } = default!;
    }
}
