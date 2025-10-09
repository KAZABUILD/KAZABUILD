using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class GetM2SlotSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Size { get; set; }

        public List<string>? KeyType { get; set; }

        public List<string>? Interface { get; set; }
    }
}
