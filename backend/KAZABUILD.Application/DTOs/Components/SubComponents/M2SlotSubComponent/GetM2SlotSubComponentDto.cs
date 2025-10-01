using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class GetM2SlotSubComponentDto : CreateBaseSubComponentDto
    {
        public List<string>? Size { get; set; }

        public List<string>? KeyType { get; set; }

        public List<string>? Interface { get; set; }
    }
}
