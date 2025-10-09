using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildTag
{
    public class CreateBuildTagDto
    {
        /// <summary>
        /// Id of the Build the Tag describes.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Id of the Tag describing the Build.
        /// </summary>
        [Required]
        public Guid TagId { get; set; } = default!;
    }
}
