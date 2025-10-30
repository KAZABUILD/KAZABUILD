using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.SubComponents
{
    /// <summary>
    /// Base SubComponent class. SubComponents are objects which are shared between components and can appear multiple times inside one.
    /// Represents basic data shared among all SubComponents. 
    /// </summary>
    public class BaseSubComponent
    {
        //Base sub components fields, shared between all sub components
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// The name of the SubComponent. 
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Type of the SubComponent. Used to distinguish between inherited classes in the database.
        /// </summary>
        [Required]
        [EnumDataType(typeof(SubComponentType))]
        public SubComponentType Type { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Staff only note.
        /// </summary>
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<ComponentPart> Components { get; set; } = [];
        public ICollection<SubComponentPart> MainSubComponents { get; set; } = [];
        public ICollection<SubComponentPart> SubComponents { get; set; } = [];
        public ICollection<Image> Images { get; set; } = [];
    }
}
