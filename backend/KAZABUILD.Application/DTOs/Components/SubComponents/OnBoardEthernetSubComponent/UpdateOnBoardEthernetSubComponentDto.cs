using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent
{
    public class UpdateOnboardEthernetSubComponentDto : UpdateBaseSubComponentDto
    {
        /// <summary>
        /// The network Speed (e.g., 2.5 GB/s, 1 GB/s).
        /// </summary>
        [StringLength(50, ErrorMessage = "Size cannot be longer than 50 characters!")]
        public string? Speed { get; set; } = default!;

        /// <summary>
        /// The network Controller model.
        /// </summary>
        [StringLength(50, ErrorMessage = "Controller cannot be longer than 50 characters!")]
        public string? Controller { get; set; } = default!;
    }
}
