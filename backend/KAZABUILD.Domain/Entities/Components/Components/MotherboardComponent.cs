using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Motherboard which connect all the other components together.
    /// </summary>
    public class MotherboardComponent : BaseComponent
    {
        /// <summary>
        /// CPU Socket Type supported by the Motherboard (e.g., AM5, LGA1700, TR4).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Motherboard (e.g., ATX, Micro-ATX, Mini-ITX).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// Chipset Type used by the Motherboard (e.g., Z790, B650, X670E).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string ChipsetType { get; set; } = default!;

        /// <summary>
        /// Which generation of the DDR (Double Data Rate) the Motherboard supports (e.g., DDR4, DDR5).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string RAMType { get; set; } = default!;

        /// <summary>
        /// The Amount of expansion Slots available for RAM.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public string? RAMSlotsAmount { get; set; }
    }
}
