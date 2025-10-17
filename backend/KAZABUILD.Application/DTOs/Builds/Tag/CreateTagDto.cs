using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.Tag
{
    public class CreateTagDto
    {
        /// <summary>
        /// The Name of the Tag.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Explanation of what the Tag is Describing.
        /// </summary>
        [Required]
        [StringLength(500, ErrorMessage = "Description cannot be longer than 500 characters!")]
        public string Description { get; set; } = default!;
    }
}
