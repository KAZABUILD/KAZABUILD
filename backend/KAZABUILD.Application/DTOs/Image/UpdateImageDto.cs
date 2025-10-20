using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class UpdateImageDto
    {
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
