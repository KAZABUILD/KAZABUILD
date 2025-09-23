using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    public class BaseSubComponent
    {
        //Base sub components fields, shared between all sub components
        [Key]
        public Guid Id { get; set; }

        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        [Required]
        [EnumDataType(typeof(SubComponentType))]
        public SubComponentType Type { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<ComponentPart> Components { get; set; } = [];
        public ICollection<SubComponentPart> MainSubComponents { get; set; } = [];
        public ICollection<SubComponentPart> SubComponents { get; set; } = [];
    }
}
