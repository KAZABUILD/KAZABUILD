using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildComponent
{
    public class UpdateBuildComponentDto
    {
        /// <summary>
        /// Amount of the Component used in the Build.
        /// </summary>
        [Range(1, 100, ErrorMessage = "Amount must be between 1 and 100!")]
        public int? Quantity { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
