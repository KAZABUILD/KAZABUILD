using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.Tag
{
    public class UpdateTagDto
    {
        /// <summary>
        /// The Name of the Tag.
        /// </summary>
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string? Name { get; set; }

        /// <summary>
        /// Explanation of what the Tag is Describing.
        /// </summary>
        [StringLength(500, ErrorMessage = "Description cannot be longer than 500 characters!")]
        public string? Description { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
