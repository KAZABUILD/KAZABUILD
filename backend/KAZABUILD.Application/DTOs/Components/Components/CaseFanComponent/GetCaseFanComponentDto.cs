using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent
{
    public class GetCaseFanComponentDto : GetBaseComponentDto
    {
        [Range(20, 500, ErrorMessage = "Fan size must be between 20 mm and 500 mm")]
        public decimal? SizeStart { get; set; }

        [Range(20, 500, ErrorMessage = "Fan size must be between 20 mm and 500 mm")]
        public decimal? SizeEnd { get; set; }

        [Range(1, 20, ErrorMessage = "Quantity must be between 1 and 20")]
        public int? QuantityStart { get; set; }

        [Range(1, 20, ErrorMessage = "Quantity must be between 1 and 20")]
        public int? QuantityEnd { get; set; }

        [Range(0, 30, ErrorMessage = "Minimum airflow must be between 0 and 30 CMM")]
        public decimal? MinAirflowStart { get; set; }

        [Range(0, 30, ErrorMessage = "Minimum airflow must be between 0 and 30 CMM")]
        public decimal? MinAirflowEnd { get; set; }

        [Range(0, 30, ErrorMessage = "Maximum airflow must be between 0 and 30 CMM")]
        public decimal? MaxAirflowStart { get; set; }

        [Range(0, 30, ErrorMessage = "Maximum airflow must be between 0 and 30 CMM")]
        public decimal? MaxAirflowEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Minimum noise level must be between 0 and 100 dB")]
        public int? MinNoiseLevelStart { get; set; }

        [Range(0, 100, ErrorMessage = "Minimum noise level must be between 0 and 100 dB")]
        public int? MinNoiseLevelEnd { get; set; }

        [Range(0, 100, ErrorMessage = "Maximum noise level must be between 0 and 100 dB")]
        public int? MaxNoiseLevelStart { get; set; }

        [Range(0, 100, ErrorMessage = "Maximum noise level must be between 0 and 100 dB")]
        public int? MaxNoiseLevelEnd { get; set; }

        public bool? PulseWidthModulation { get; set; }

        public List<string>? LEDType { get; set; }

        public List<string>? ConnectorType { get; set; }

        public List<string>? ControllerType { get; set; }

        [Range(0, 20, ErrorMessage = "Static pressure must be between 0 and 20 mmH2O")]
        public decimal? StaticPressureAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Static pressure must be between 0 and 20 mmH2O")]
        public decimal? StaticPressureAmountEnd { get; set; }

        public List<string>? FlowDirection { get; set; }
    }
}
