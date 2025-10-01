using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class GetPCIeSlotSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Gen { get; set; }

        public List<string>? Lanes { get; set; }
    }
}
