using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Domain.Enums;
namespace KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent
{
    public class GetPortSubComponentDto : GetBaseSubComponentDto
    {
        public List<PortType>? PortType { get; set; }
    }
}
