using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentCompatibility
{
    public class CreateComponentCompatibilityDto
    {
        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        public Guid CompatibleComponentId { get; set; } = default!;
    }
}
