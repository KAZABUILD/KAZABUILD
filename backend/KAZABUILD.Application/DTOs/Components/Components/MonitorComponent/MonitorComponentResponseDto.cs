using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Application.DTOs.Components.Components.MonitorComponent
{
    public class MonitorComponentResponseDto : BaseComponentResponseDto
    {
        public decimal? ScreenSize { get; set; }

        public int? HorizontalResolution { get; set; }

        public int? VerticalResolution { get; set; }

        public decimal? MaxRefreshRate { get; set; }

        public string? PanelType { get; set; }

        public decimal? ResponseTime { get; set; }

        public string? ViewingAngle { get; set; }

        public string? AspectRatio { get; set; }

        public decimal? MaxBrightness { get; set; }

        public string? HighDynamicRangeType { get; set; }

        public string? AdaptiveSyncType { get; set; }
    }
}
