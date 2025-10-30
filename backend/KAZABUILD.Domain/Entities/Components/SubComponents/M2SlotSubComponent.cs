using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// SubComponent representing a common motherboard slot of type M.2.
    /// </summary>
    public class M2SlotSubComponent : BaseSubComponent
    {
        /// <summary>
        /// M.2 form factor size (e.g., 2280, 22110)
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Size cannot be longer than 100 characters!")]
        public string Size { get; set; } = default!;

        /// <summary>
        /// The Key Type of the M.2 slot (e.g., M key, B key, B+M key).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Key Type cannot be longer than 50 characters!")]
        public string KeyType { get; set; } = default!;

        /// <summary>
        /// The M.2 Interface specification (e.g., PCIe 4.0 x4)
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "cannot be longer than 50 characters!")]
        public string Interface { get; set; } = default!;
    }
}
