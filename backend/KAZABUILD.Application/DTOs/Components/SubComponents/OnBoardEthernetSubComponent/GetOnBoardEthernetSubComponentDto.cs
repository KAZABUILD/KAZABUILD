using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent
{
    public class GetOnboardEthernetSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Speed { get; set; }

        public List<string>? Controller { get; set; }
    }
}
