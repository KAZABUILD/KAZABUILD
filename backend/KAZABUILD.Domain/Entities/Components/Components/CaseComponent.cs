using KAZABUILD.Domain.ValueObjects;

using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Case which stores all the other components inside and allows additional outlets for the user.
    /// </summary>
    public class CaseComponent : BaseComponent
    {
        /// <summary>
        /// The physical specification of the case (e.g., ATX Mid Tower, Full Tower, Mini-ITX).
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Form Factor cannot be longer than 100 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// Is the power supply covered.
        /// </summary>
        [Required]
        public bool PowerSupplyShrouded { get; set; } = default!;

        /// <summary>
        /// Amount of power in the built-in power supply in Watts.
        /// leave empty if no power supply.
        /// </summary>
        [Range(0, 2500, ErrorMessage = "Power Supply must be between 0 and 2,500 Watts")]
        [Precision(6, 2)]
        public decimal? PowerSupplyAmount { get; set; }

        /// <summary>
        /// Does the case include a transparent side panel.
        /// </summary>
        [Required]
        public bool HasTransparentSidePanel { get; set; } = default!;

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
        [Precision(5, 2)]
        public decimal MaxVideoCardLength { get; set; } = default!;

        /// <summary>
        /// Maximum supported height of a CPU Cooler that can fit in inside the case in mm.
        /// </summary>
        [Required]
        [Range(10, 400, ErrorMessage = "Max CPU Cooler Height must be between 10 and 400 mm")]
        [Precision(5, 2)]
        public decimal MaxCPUCoolerHeight { get; set; } = default!;

        /// <summary>
        /// The number of internal spaces for holding Seta or HDD Drives,
        /// 3.5 - 101.6 mm width.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "Internal 3.5 Bay Amount must be between 0 and 15")]
        public int Internal35BayAmount { get; set; } = default!;

        /// <summary>
        /// The number of internal spaces for holding HDD or SDD Drives,
        /// 2.5 - 69.85 mm width.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "Internal 2.5 Bay Amount must be between 0 and 15")]
        public int Internal25BayAmount { get; set; } = default!;

        /// <summary>
        /// The number of external spaces for holding Seta or HDD Drives,
        /// 3.5 - 101.6 mm width.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int External35BayAmount { get; set; } = default!;

        /// <summary>
        /// The number of external spaces for holding Seta or HDD Drives,
        /// 5.25 - 133.35 mm width.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "External 3.5 Bay Amount must be between 0 and 15")]
        public int External525BayAmount { get; set; } = default!;

        /// <summary>
        /// The number of slots where expansion cards can be inserted.
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "ExpansionSlotAmount must be between 0 and 20")]
        public int ExpansionSlotAmount { get; set; } = default!;

        /// <summary>
        /// The size of the case in mm. Includes Depth, Width, Height.
        /// </summary>
        [Required]
        public Dimension Dimensions { get; set; } = default!;

        /// <summary>
        /// The volume of the case in liters.
        /// </summary>
        [Precision(12, 8)]
        public decimal Volume => Dimensions.Height * Dimensions.Width * Dimensions.Depth / 1000000;

        /// <summary>
        /// The weight of the case in kg.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Weight must be between 0 and 100 kg")]
        [Precision(5, 2)]
        public decimal Weight { get; set; } = default!;

        /// <summary>
        /// If the case supports connecting the motherboard in an alternative position.
        /// </summary>
        [Required]
        public bool SupportsRearConnectingMotherboard { get; set; } = default!;
    }
}
