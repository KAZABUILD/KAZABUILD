using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent
{
    public class OnboardEthernetSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? Speed { get; set; }

        public string? Controller { get; set; }
    }
}
