using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// Represents a generic port (e.g., USB, HDMI, DisplayPort).
    /// </summary>
    public class CpuPowerSubComponent : BaseSubComponent
    {
        /// <summary>
        /// Type of the port.
        /// </summary>
        public CpuPowerType CpuPowerType { get; set; }
    }
}
