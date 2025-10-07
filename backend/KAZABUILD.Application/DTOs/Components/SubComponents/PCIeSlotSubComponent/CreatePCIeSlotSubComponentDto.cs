using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class CreatePCIeSlotSubComponentDto : CreateBaseSubComponentDto
    {
        /// <summary>
        /// The version of the PCIe slot (e.g., 5.0, 4.0)
        /// </summary>
        [Required]
        [StringLength(5, ErrorMessage = "Gen cannot be longer than 5 characters!")]
        public string Gen { get; set; } = default!;

        /// <summary>
        /// The number of lanes for the PCIe slot (e.g., x1, x4, x8, x16).
        /// </summary>
        [Required]
        [StringLength(5, ErrorMessage = "Lanes cannot be longer than 5 characters!")]
        public string Lanes { get; set; } = default!;
    }
}
