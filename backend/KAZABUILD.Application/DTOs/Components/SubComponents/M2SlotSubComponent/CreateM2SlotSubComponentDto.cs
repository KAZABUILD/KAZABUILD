using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class CreateM2SlotSubComponentDto : CreateBaseSubComponentDto
    {

        [Required]
        [StringLength(100, ErrorMessage = "Size cannot be longer than 50 characters!")]
        public string Size { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Key Type cannot be longer than 50 characters!")]
        public string KeyType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "cannot be longer than 50 characters!")]
        public string Interface { get; set; } = default!;
    }
}
