using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// SubComponent representing motherboard Onboard Ethernet.
    /// </summary>
    public class M2SlotSubcomponent : BaseSubComponent
    {
        /// <summary>
        /// The network speed (e.g., 2.5 Gb/s, 1 Gb/s).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Size cannot be longer than 50 characters!")]
        public string Speed { get; set; } = default!;

        /// <summary>
        /// The network controller model.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Controller cannot be longer than 50 characters!")]
        public string Controller { get; set; } = default!;

    }
}
