using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    public class UpdateBaseSubComponentDto
    {
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string? Name { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
