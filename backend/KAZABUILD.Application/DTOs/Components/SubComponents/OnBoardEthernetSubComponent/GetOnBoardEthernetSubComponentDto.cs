using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnBoardEthernetSubComponent
{
    public class GetOnBoardEthernetSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Speed { get; set; }

        public List<string>? Controller { get; set; }
    }
}
