using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnBoardEthernetSubComponent
{
    public class CreateOnBoardEthernetSubComponentDto : CreateBaseSubComponentDto
    {
        [Required]
        [StringLength(50, ErrorMessage = "Speed cannot be longer than 50 characters!")]
        public string Speed { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Controller cannot be longer than 50 characters!")]
        public string Controller { get; set; } = default!;
    }
}
