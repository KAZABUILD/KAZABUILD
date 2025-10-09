using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.StorageComponent
{
    public class StorageComponentResponseDto : BaseComponentResponseDto
    {
        public string? Series { get; set; }

        public decimal? Capacity { get; set; }

        public string? DriveType { get; set; }

        public string? FormFactor { get; set; }

        public string? Interface { get; set; }

        public bool? HasNVMe { get; set; }
    }
}
