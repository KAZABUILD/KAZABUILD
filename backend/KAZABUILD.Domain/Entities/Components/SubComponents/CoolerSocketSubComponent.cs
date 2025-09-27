using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// Represents a CPU cooler socket compatibility.
    /// </summary>
    public class CoolerSocketSubComponent : BaseSubComponent
    {
        /// <summary>
        /// Socket Type supported by the cooler (e.g., AM5, LGA1700, TR4).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Socket type cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;
    }
}
