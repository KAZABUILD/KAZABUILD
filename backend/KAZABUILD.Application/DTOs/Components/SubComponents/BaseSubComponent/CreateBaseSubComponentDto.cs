using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    public class CreateBaseSubComponentDto
    {
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        [Required]
        [EnumDataType(typeof(SubComponentType))]
        public SubComponentType Type { get; set; }
    }
}
