using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Monitor which displays information from the computer to the user.
    /// </summary>
    public class MonitorComponent : BaseComponent
    {
        /// <summary>
        /// Screen Size in inches (measured diagonally).
        /// </summary>
        [Required]
        [Range(1, 200, ErrorMessage = "Screen Size must be between 1 and 200 inches")]
        [Precision(9, 6)]
        public decimal ScreenSize { get; set; } = default!;

        /// <summary>
        /// Horizontal Resolution in pixels.
        /// </summary>
        [Required]
        [Range(160, 32000, ErrorMessage = "Horizontal Resolution must be between 160 and 32000 pixels")]
        public int HorizontalResolution { get; set; } = default!;

        /// <summary>
        /// Vertical Resolution in pixels.
        /// </summary>
        [Required]
        [Range(160, 32000, ErrorMessage = "Vertical Resolution must be between 160 and 32000 pixels")]
        public int VerticalResolution { get; set; } = default!;

        /// <summary>
        /// Maximum Monitor Refresh Rate in Hz.
        /// </summary>
        [Required]
        [Range(5, 2000, ErrorMessage = "Refresh Rate must be between 5 and 2000 Hz")]
        [Precision(6, 2)]
        public decimal MaxRefreshRate { get; set; } = default!;

        /// <summary>
        /// Type of technology used to generate images on the monitor (e.g., IPS, VA, TN, OLED).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Panel Type cannot be longer than 50 characters!")]
        public string PanelType { get; set; } = default!;

        /// <summary>
        /// How much times it takes for the Monitor to shift from one color to another in ms.
        /// Measured using shifting from Gray-to-Gray (GtG).
        /// </summary>
        [Required]
        [Range(0, 200, ErrorMessage = "Response Time must be between 0 and 200 ms")]
        [Precision(5, 2)]
        public decimal ResponseTime { get; set; } = default!;

        /// <summary>
        /// Maximum Viewing Angle where the screen is still visible to a human.
        /// Horizontal by vertical (e.g., 178° H x 178° V).
        /// </summary>
        [Required]
        [StringLength(20, ErrorMessage = "Viewing Angle cannot be longer than 20 characters!")]
        public string ViewingAngle { get; set; } = default!;

        /// <summary>
        /// Aspect Ratio of the monitor.
        /// Width to height (e.g., 16:9, 21:9, 32:9).
        /// </summary>
        [Required]
        [StringLength(10, ErrorMessage = "Aspect Ratio cannot be longer than 10 characters!")]
        public string AspectRatio { get; set; } = default!;

        /// <summary>
        /// Maximum brightness of the Monitor in nits (cd/m2).
        /// </summary>
        [Range(0, 100, ErrorMessage = "Max Brightness must be between 0 and 5000 nits")]
        [Precision(6, 2)]
        public decimal? MaxBrightness { get; set; }

        /// <summary>
        /// What type of High Dynamic Range (HDR), if any, does the Monitor supports (e.g., HDR10, HDR600, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "High Dynamic Range Type cannot be longer than 50 characters!")]
        public string? HighDynamicRangeType { get; set; }

        /// <summary>
        /// Type of technology that synchronizes the refresh rate of a monitor with the output of a graphics card (e.g., FreeSync, G-SYNC, None).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Adaptive Sync Type cannot be longer than 50 characters!")]
        public string AdaptiveSyncType { get; set; } = default!;
    }
}
