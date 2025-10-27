using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MonitorComponent
{
    public class UpdateMonitorComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// Screen Size in inches (measured diagonally).
        /// </summary>
        [Range(1, 200, ErrorMessage = "Screen Size must be between 1 and 200 inches")]
        public decimal? ScreenSize { get; set; }

        /// <summary>
        /// Horizontal Resolution in pixels.
        /// </summary>
        [Range(160, 32000, ErrorMessage = "Horizontal Resolution must be between 160 and 32000 pixels")]
        public int? HorizontalResolution { get; set; }

        /// <summary>
        /// Vertical Resolution in pixels.
        /// </summary>
        [Range(160, 32000, ErrorMessage = "Vertical Resolution must be between 160 and 32000 pixels")]
        public int? VerticalResolution { get; set; }

        /// <summary>
        /// Maximum Monitor Refresh Rate in Hz.
        /// </summary>
        [Range(5, 2000, ErrorMessage = "Refresh Rate must be between 5 and 2000 Hz")]
        public decimal? MaxRefreshRate { get; set; }

        /// <summary>
        /// Type of technology used to generate images on the Monitor (e.g., IPS, VA, TN, OLED).
        /// </summary>
        [StringLength(50, ErrorMessage = "Panel Type cannot be longer than 50 characters!")]
        public string? PanelType { get; set; }

        /// <summary>
        /// How much times it takes for the Monitor to shift from one color to another in ms.
        /// Measured using shifting from Gray-to-Gray (GtG).
        /// </summary>
        [Range(0, 200, ErrorMessage = "Response Time must be between 0 and 200 ms")]
        public decimal? ResponseTime { get; set; }

        /// <summary>
        /// Maximum Viewing Angle where the screen is still visible to a human.
        /// Horizontal by vertical (e.g., 178° H x 178° V).
        /// </summary>
        [StringLength(20, ErrorMessage = "Viewing Angle cannot be longer than 20 characters!")]
        public string? ViewingAngle { get; set; }

        /// <summary>
        /// Aspect Ratio of the Monitor.
        /// Width to height (e.g., 16:9, 21:9, 32:9).
        /// </summary>
        [StringLength(10, ErrorMessage = "Aspect Ratio cannot be longer than 10 characters!")]
        public string? AspectRatio { get; set; }

        /// <summary>
        /// Maximum brightness of the Monitor in nits (cd/m2).
        /// </summary>
        [Range(0, 5000, ErrorMessage = "Max Brightness must be between 0 and 5000 nits")]
        public decimal? MaxBrightness { get; set; }

        /// <summary>
        /// What type of High Dynamic Range (HDR), if any, does the Monitor supports (e.g., HDR10, HDR600, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "High Dynamic Range Type cannot be longer than 50 characters!")]
        public string? HighDynamicRangeType { get; set; }

        /// <summary>
        /// Type of technology that synchronizes the refresh rate of a Monitor with the output of a graphics card (e.g., FreeSync, G-SYNC, None).
        /// </summary>
        [StringLength(50, ErrorMessage = "Adaptive Sync Type cannot be longer than 50 characters!")]
        public string? AdaptiveSyncType { get; set; } = default!;
    }
}
