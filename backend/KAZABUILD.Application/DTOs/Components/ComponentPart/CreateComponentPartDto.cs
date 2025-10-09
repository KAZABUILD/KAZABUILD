using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentPart
{
    public class CreateComponentPartDto
    {
        /// <summary>
        /// Id of the component.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Id of the subComponent.
        /// </summary>
        [Required]
        public Guid SubComponentId { get; set; } = default!;

        /// <summary>
        /// How many of the subComponent is a part of the component.
        /// </summary>
        [Required]
        [Range(1, 50, ErrorMessage = "Amount must be between 1 and 50!")]
        public int Amount { get; set; }
    }
}
