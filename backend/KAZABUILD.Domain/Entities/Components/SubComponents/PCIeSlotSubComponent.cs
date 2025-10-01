using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// SubComponent representing motherboard PCIe slots.
    /// </summary>
    public class PCIeSlotSubComponent : BaseSubComponent
    {
        /// <summary>
        /// The version of the PCIe slot (e.g., 5.0, 4.0)
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string Gen { get; set; } = default!;

        /// <summary>
        /// The number of lanes for the PCIe slot (e.g., x1, x4, x8, x16).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Error-Correcting Code cannot be longer than 50 characters!")]
        public string Lanes { get; set; } = default!;

        /// <summary>
        /// The quantity of this specific PCIe slot type available on the motherboard.
        /// </summary>
        [Required]
        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10")]
        public int Quantity { get; set; } =default!;
    }
}
