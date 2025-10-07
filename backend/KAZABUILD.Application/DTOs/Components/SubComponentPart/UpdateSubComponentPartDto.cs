using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponentPart
{
    public class UpdateSubComponentPartDto
    {
        /// <summary>
        /// How many of the subComponent is a part of the main subComponent.
        /// </summary>
        [Range(1, 50, ErrorMessage = "Amount must be between 1 and 50!")]
        public int? Amount { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
