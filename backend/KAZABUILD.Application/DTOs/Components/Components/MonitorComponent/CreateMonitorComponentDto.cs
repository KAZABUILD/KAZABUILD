using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MonitorComponent
{
    public class CreateMonitorComponentDto : CreateBaseComponentDto
    {
        [Required]
        [Range(1, 200, ErrorMessage = "Screen Size must be between 1 and 200 inches")]
        public decimal ScreenSize { get; set; } = default!;

        [Required]
        [Range(160, 32000, ErrorMessage = "Horizontal Resolution must be between 160 and 32000 pixels")]
        public int HorizontalResolution { get; set; } = default!;

        [Required]
        [Range(160, 32000, ErrorMessage = "Vertical Resolution must be between 160 and 32000 pixels")]
        public int VerticalResolution { get; set; } = default!;

        [Required]
        [Range(5, 2000, ErrorMessage = "Refresh Rate must be between 5 and 2000 Hz")]
        public decimal MaxRefreshRate { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Panel Type cannot be longer than 50 characters!")]
        public string PanelType { get; set; } = default!;

        [Required]
        [Range(0, 200, ErrorMessage = "Response Time must be between 0 and 200 ms")]
        public decimal ResponseTime { get; set; } = default!;

        [Required]
        [StringLength(20, ErrorMessage = "Viewing Angle cannot be longer than 20 characters!")]
        public string ViewingAngle { get; set; } = default!;

        [Required]
        [StringLength(10, ErrorMessage = "Aspect Ratio cannot be longer than 10 characters!")]
        public string AspectRatio { get; set; } = default!;

        [Range(0, 100, ErrorMessage = "Max Brightness must be between 0 and 5000 nits")]
        public decimal? MaxBrightness { get; set; }

        [StringLength(50, ErrorMessage = "High Dynamic Range Type cannot be longer than 50 characters!")]
        public string? HighDynamicRangeType { get; set; }

        [Required]
        [StringLength(50, ErrorMessage = "Adaptive Sync Type cannot be longer than 50 characters!")]
        public string AdaptiveSyncType { get; set; } = default!;
    }
}
