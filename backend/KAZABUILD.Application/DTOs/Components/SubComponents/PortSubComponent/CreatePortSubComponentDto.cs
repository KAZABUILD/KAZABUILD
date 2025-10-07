using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent
{
    public class CreatePortSubComponentDto : CreateBaseSubComponentDto
    {
        /// <summary>
        /// Type of the port.
        /// </summary>
        [Required]
        public PortType PortType { get; set; } = default!;
    }
}
