using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class CreateM2SlotSubComponentDto : CreateBaseSubComponentDto
    {
        /// <summary>
        /// M.2 form factor size (e.g., 2280, 22110)
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Size cannot be longer than 50 characters!")]
        public string Size { get; set; } = default!;

        /// <summary>
        /// The Key Type of the M.2 slot (e.g., M key, B key, B+M key).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Key Type cannot be longer than 50 characters!")]
        public string KeyType { get; set; } = default!;

        /// <summary>
        /// The M.2 interface specification (e.g., PCIe 4.0 x4)
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "cannot be longer than 50 characters!")]
        public string Interface { get; set; } = default!;
    }
}
