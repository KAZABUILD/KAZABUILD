using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildComponent
{
    public class CreateBuildComponentDto
    {
        /// <summary>
        /// Id of the Build the Component is used in.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Id of the Component used in the Build.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Amount of the Component used in the Build.
        /// </summary>
        [Required]
        [Range(1, 100, ErrorMessage = "Amount must be between 1 and 100!")]
        public int Quantity { get; set; } = default!;
    }
}
