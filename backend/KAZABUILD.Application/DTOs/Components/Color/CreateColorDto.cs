using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Color
{
    public class CreateColorDto
    {
        /// <summary>
        /// Color Code as an id.
        /// </summary>
        [Required]
        [StringLength(7, ErrorMessage = "Color must be a valid hex code like #FFFFFF")]
        [RegularExpression(@"^#(?:[0-9a-fA-F]{3}){1,2}$", ErrorMessage = "Color must be a valid hex format (#RGB or #RRGGBB)")]
        public string ColorCode { get; set; } = default!;

        /// <summary>
        /// Name of the color.
        /// </summary>
        [Required]
        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public string ColorName { get; set; } = default!;
    }
}
