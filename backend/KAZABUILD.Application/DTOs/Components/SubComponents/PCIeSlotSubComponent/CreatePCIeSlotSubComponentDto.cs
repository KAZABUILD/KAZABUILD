using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class CreatePCIeSlotSubComponentDto : CreateBaseSubComponentDto
    {
        [Required]
        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string Gen { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string Lanes { get; set; } = default!;

        [Required]
        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10")]
        public int Quantity { get; set; } = default!;
    }
}
