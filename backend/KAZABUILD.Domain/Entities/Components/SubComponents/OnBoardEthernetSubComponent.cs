using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// SubComponent representing motherboard's Onboard Ethernet.
    /// </summary>
    public class OnboardEthernetSubComponent : BaseSubComponent
    {
        /// <summary>
        /// The network Speed (e.g., 2.5 GB/s, 1 GB/s).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Speed cannot be longer than 50 characters!")]
        public string Speed { get; set; } = default!;

        /// <summary>
        /// The network Controller model.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Controller cannot be longer than 50 characters!")]
        public string Controller { get; set; } = default!;

    }
}
