using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MonitorComponent
{
    public class GetMonitorComponentDto : GetBaseComponentDto
    {
        [Range(1, 200, ErrorMessage = "Screen Size must be between 1 and 200 inches")]
        public decimal? ScreenSizeStart { get; set; }

        [Range(1, 200, ErrorMessage = "Screen Size must be between 1 and 200 inches")]
        public decimal? ScreenSizeEnd { get; set; }

        [Range(160, 32000, ErrorMessage = "Horizontal Resolution must be between 160 and 32000 pixels")]
        public int? HorizontalResolutionStart { get; set; }

        [Range(160, 32000, ErrorMessage = "Horizontal Resolution must be between 160 and 32000 pixels")]
        public int? HorizontalResolutionEnd { get; set; }

        [Range(160, 32000, ErrorMessage = "Vertical Resolution must be between 160 and 32000 pixels")]
        public int? VerticalResolutionStart { get; set; }

        [Range(160, 32000, ErrorMessage = "Vertical Resolution must be between 160 and 32000 pixels")]
        public int? VerticalResolutionEnd { get; set; }

        [Range(5, 2000, ErrorMessage = "Refresh Rate must be between 5 and 2000 Hz")]
        public decimal? MaxRefreshRateStart { get; set; }

        [Range(5, 2000, ErrorMessage = "Refresh Rate must be between 5 and 2000 Hz")]
        public decimal? MaxRefreshRateEnd { get; set; }

        public List<string>? PanelType { get; set; }

        [Range(0, 200, ErrorMessage = "Response Time must be between 0 and 200 ms")]
        public decimal? ResponseTimeStart { get; set; }

        [Range(0, 200, ErrorMessage = "Response Time must be between 0 and 200 ms")]
        public decimal? ResponseTimeEnd { get; set; }

        public List<string>? ViewingAngleStart { get; set; }

        public List<string>? ViewingAngleEnd { get; set; }

        public List<string>? AspectRatioStart { get; set; }

        public List<string>? AspectRatioEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Max Brightness must be between 0 and 5000 nits")]
        public decimal? MaxBrightnessStart { get; set; }

        [Range(0, 100, ErrorMessage = "Max Brightness must be between 0 and 5000 nits")]
        public decimal? MaxBrightnessEnd { get; set; }

        public List<string>? HighDynamicRangeType { get; set; }

        public List<string>? AdaptiveSyncType { get; set; }
    }
}
