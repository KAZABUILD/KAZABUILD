using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class CreateMotherboardComponentDto : CreateBaseComponentDto
    {
        [Required]
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string ChipsetType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string RAMType { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public decimal? RAMSlotsAmount { get; set; }
    }
}
