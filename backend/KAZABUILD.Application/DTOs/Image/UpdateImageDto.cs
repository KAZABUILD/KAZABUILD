using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class UpdateImageDto
    {

        /// <summary>
        /// Name which is used for the image in the html.
        /// Can be used to match the returned images to their proper name.
        /// </summary>
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string? Name { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
