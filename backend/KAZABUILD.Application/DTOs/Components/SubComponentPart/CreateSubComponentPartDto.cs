using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponentPart
{
    public class CreateSubComponentPartDto
    {
        [Required]
        public Guid MainSubComponentId { get; set; } = default!;

        [Required]
        public Guid SubComponentId { get; set; } = default!;

        [Required]
        [Range(1, 50, ErrorMessage = "Amount must be between 1 and 50!")]
        public int Amount { get; set; }
    }
}
