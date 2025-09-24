using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentPart
{
    public class CreateComponentPartDto
    {
        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        public Guid SubComponentId { get; set; } = default!;
    }
}
