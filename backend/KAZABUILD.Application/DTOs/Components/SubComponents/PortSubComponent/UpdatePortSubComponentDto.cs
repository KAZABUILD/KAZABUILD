using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent
{
    public class UpdatePortSubComponentDto : UpdateBaseSubComponentDto
    {
        public PortType? PortType { get; set; }
    }
}
