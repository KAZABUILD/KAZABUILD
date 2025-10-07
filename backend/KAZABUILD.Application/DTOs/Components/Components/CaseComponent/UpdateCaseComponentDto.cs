using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Domain.ValueObjects;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseComponent
{
    public class UpdateCaseComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// The physical specification of the case (e.g., ATX Mid Tower, Full Tower, Mini-ITX).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Form Factor cannot be longer than 100 characters!")]
        public string? FormFactor { get; set; }

        /// <summary>
        /// Is the power supply covered.
        /// </summary>
        [Required]
        public bool? PowerSupplyShrouded { get; set; }

        /// <summary>
        /// Amount of power in the built-in power supply in Watts.
        /// leave empty if no power supply.
        /// </summary>
        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        public decimal? PowerSupplyAmount { get; set; }

        /// <summary>
        /// Does the case include a transparent side panel.
        /// </summary>
        public bool? HasTransparentSidePanel { get; set; }

        /// <summary>
        /// What type of side panel, if any, is in the case, (e.g., Tempered Glass, Acrylic, Solid).
        /// </summary>
        [StringLength(50, ErrorMessage = "Side Panel Type cannot be longer than 50 characters!")]
        public string? SidePanelType { get; set; }

        /// <summary>
        /// Maximum supported length of a video card that can fit in inside the case in mm.
        /// </summary>
        [Required]
        [Range(10, 600, ErrorMessage = "Maximum Video Card Length must be between 10 and 600 mm")]
        public decimal? MaxVideoCardLength { get; set; }

        /// <summary>
        /// Maximum supported height of a CPU Cooler that can fit in inside the case in mm.
        /// </summary>
        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        public decimal? MaxCPUCoolerHeight { get; set; }

        /// <summary>
        /// The number of internal spaces for holding Seta or HDD Drives,
        /// 3.5 - 101.6 mm width.
        /// </summary>
        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int? Internal35BayAmount { get; set; }

        /// <summary>
        /// The number of internal spaces for holding HDD or SDD Drives,
        /// 2.5 - 69.85 mm width.
        /// </summary>
        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int? Internal25BayAmount { get; set; }

        /// <summary>
        /// The number of external spaces for holding Seta or HDD Drives,
        /// 3.5 - 101.6 mm width.
        /// </summary>
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External35BayAmount { get; set; }

        /// <summary>
        /// The number of external spaces for holding Seta or HDD Drives,
        /// 5.25 - 133.35 mm width.
        /// </summary>
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int? External525BayAmount { get; set; }

        /// <summary>
        /// The number of slots where expansion cards can be inserted.
        /// </summary>
        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int? ExpansionSlotAmount { get; set; }

        /// <summary>
        /// The Width of the case in mm.
        /// </summary>
        public decimal? Width { get; set; }

        /// <summary>
        /// The Height of the case in mm.
        /// </summary>
        public decimal? Height { get; set; }

        /// <summary>
        /// The Depth of the case in mm.
        /// </summary>
        public decimal? Depth { get; set; }

        /// <summary>
        /// The weight of the case in kg.
        /// </summary>
        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        public decimal? Weight { get; set; }

        /// <summary>
        /// If the case supports connecting the motherboard in an alternative position.
        /// </summary>
        public bool? SupportsRearConnectingMotherboard { get; set; }
    }
}
