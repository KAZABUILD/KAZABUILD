using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponentPart
{
    public class CreateSubComponentPartDto
    {
        /// <summary>
        /// Id of the main component.
        /// </summary>
        [Required]
        public Guid MainSubComponentId { get; set; } = default!;

        /// <summary>
        /// Id of the subComponent that is part of the main subComponent.
        /// </summary>
        [Required]
        public Guid SubComponentId { get; set; } = default!;

        /// <summary>
        /// How many of the subComponent is a part of the main subComponent.
        /// </summary>
        [Required]
        [Range(1, 50, ErrorMessage = "Amount must be between 1 and 50!")]
        public int Amount { get; set; }
    }
}
