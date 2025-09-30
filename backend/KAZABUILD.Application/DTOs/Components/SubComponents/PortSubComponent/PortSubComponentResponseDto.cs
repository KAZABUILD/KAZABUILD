using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent
{
    public class PortSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public PortType? PortType { get; set; }
    }
}
