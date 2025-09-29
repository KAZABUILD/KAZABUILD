using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    public class UpdateBaseComponentDto
    {
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string? Name { get; set; }

        [StringLength(50, ErrorMessage = "Manufacturer cannot be longer than 50 characters!")]
        public string? Manufacturer { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? Release { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
