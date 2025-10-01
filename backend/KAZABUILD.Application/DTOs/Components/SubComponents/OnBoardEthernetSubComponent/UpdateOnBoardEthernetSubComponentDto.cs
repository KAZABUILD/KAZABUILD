using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent
{
    public class UpdateOnboardEthernetSubComponentDto : UpdateBaseSubComponentDto
    {
        [StringLength(50, ErrorMessage = "Size cannot be longer than 50 characters!")]
        public string? Speed { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Controller cannot be longer than 50 characters!")]
        public string? Controller { get; set; } = default!;
    }
}
