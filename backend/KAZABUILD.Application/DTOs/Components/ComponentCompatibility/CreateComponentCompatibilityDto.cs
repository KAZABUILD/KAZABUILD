using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentCompatibility
{
    public class CreateComponentCompatibilityDto
    {
        /// <summary>
        /// Id of a component to set compatibility for.s
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Id of a component compatible to the other one.
        /// </summary>
        [Required]
        public Guid CompatibleComponentId { get; set; } = default!;
    }
}
