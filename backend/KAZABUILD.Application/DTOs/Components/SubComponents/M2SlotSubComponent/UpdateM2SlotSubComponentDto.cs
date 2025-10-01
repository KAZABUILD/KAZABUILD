using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class UpdateM2SlotSubComponentDto : UpdateBaseSubComponentDto
    {
        [StringLength(100, ErrorMessage = "Size cannot be longer than 100 characters!")]
        public string? Size { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Key Type cannot be longer than 50 characters!")]
        public string? KeyType { get; set; } = default!;

        [StringLength(50, ErrorMessage = "cannot be longer than 50 characters!")]
        public string? Interface { get; set; } = default!;
    }
}
