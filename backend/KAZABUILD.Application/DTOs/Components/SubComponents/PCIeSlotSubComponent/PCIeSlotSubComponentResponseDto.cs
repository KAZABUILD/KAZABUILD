using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class PCIeSlotSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? Gen { get; set; }

        public string? Lanes { get; set; }

    }
}
