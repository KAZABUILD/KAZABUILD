using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentPart
{
    public class UpdateComponentPartDto
    {
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
