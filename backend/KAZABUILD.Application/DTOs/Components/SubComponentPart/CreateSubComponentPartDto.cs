using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponentPart
{
    public class CreateSubComponentPartDto
    {
        [Required]
        public Guid MainSubComponentId { get; set; } = default!;

        [Required]
        public Guid SubComponentId { get; set; } = default!;
    }
}
