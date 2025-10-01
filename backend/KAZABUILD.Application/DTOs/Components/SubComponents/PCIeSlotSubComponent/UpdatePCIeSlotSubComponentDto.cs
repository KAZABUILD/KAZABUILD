using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class UpdatePCIeSlotSubComponentDto : UpdateBaseSubComponentDto
    {
        [StringLength(5, ErrorMessage = "Gen cannot be longer than 50 characters!")]
        public string? Gen { get; set; } = default!;

        [StringLength(5, ErrorMessage = "Lanes cannot be longer than 50 characters!")]
        public string? Lanes { get; set; } = default!;

    }
}
