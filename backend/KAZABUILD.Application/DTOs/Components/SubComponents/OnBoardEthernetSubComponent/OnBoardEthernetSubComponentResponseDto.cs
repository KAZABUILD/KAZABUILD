using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent
{
    public class OnboardEthernetSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? Speed { get; set; }

        public string? Controller { get; set; }
    }
}
