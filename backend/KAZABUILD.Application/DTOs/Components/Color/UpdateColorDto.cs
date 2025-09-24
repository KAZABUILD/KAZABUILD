using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Color
{
    public class UpdateColorDto
    {
        [StringLength(30, ErrorMessage = "Color Name cannot be longer than 30 characters!")]
        [MinLength(3, ErrorMessage = "Color Name must be at least 3 characters long!")]
        public string? ColorName { get; set; }
    }
}
