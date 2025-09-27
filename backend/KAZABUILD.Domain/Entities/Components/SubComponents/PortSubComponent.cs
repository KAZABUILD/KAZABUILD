using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// Represents a generic port (e.g., USB, HDMI, DisplayPort).
    /// </summary>
    public class PortSubComponent : BaseSubComponent
    {
        /// <summary>
        /// Type of the port.
        /// </summary>
        [Required]
        public PortType PortType { get; set; } = default!;
    }
}
