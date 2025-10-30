using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class GetPCIeSlotSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Gen { get; set; }

        public List<string>? Lanes { get; set; }
    }
}
