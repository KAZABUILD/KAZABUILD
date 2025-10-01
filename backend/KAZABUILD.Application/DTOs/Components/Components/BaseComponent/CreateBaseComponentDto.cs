using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    public class CreateBaseComponentDto
    {
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Manufacturer cannot be longer than 50 characters!")]
        public string Manufacturer { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? Release { get; set; }

        [Required]
        [EnumDataType(typeof(ComponentType))]
        public ComponentType Type { get; set; }
    }
}
