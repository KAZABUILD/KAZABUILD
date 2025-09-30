using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.StorageComponent
{
    public class CreateStorageComponentDto : CreateBaseComponentDto
    {
        [Required]
        [StringLength(100, ErrorMessage = "Series cannot be longer than 100 characters!")]
        public string Series { get; set; } = default!;

        [Required]
        [Range(0, 8388608, ErrorMessage = "Capacity must be between 0 and 8 PB (8388608 GB)")]
        public decimal Capacity { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Type cannot be longer than 50 characters!")]
        public string DriveType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Form factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Interface cannot be longer than 50 characters!")]
        public string Interface { get; set; } = default!;

        [Required]
        public bool HasNVMe { get; set; } = default!;
    }
}
