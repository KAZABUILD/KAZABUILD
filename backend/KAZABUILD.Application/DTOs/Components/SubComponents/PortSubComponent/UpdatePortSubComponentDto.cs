using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent
{
    public class UpdatePortSubComponentDto : UpdateBaseSubComponentDto
    {
        /// <summary>
        /// Type of the port.
        /// </summary>
        public PortType? PortType { get; set; }
    }
}
