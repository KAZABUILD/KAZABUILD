using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Main Component class. Stores generic information shared among all computer components.
    /// </summary>
    public class BaseComponent
    {
        //Base components fields, shared between all components
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// The Component's name.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Who created the Component.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Manufacturer cannot be longer than 50 characters!")]
        public string Manufacturer { get; set; } = default!;

        /// <summary>
        /// The release date of the Component. Often just the year.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? Release { get; set; }

        /// <summary>
        /// Type of the Component. Used to distinguish between inherited classes in the database.
        /// </summary>
        [Required]
        [EnumDataType(typeof(ComponentType))]
        public ComponentType Type { get; set; }

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
        public ICollection<ComponentColor> Colors { get; set; } = [];
        public ICollection<ComponentPart> SubComponents { get; set; } = [];
        public ICollection<ComponentCompatibility> CompatibleComponents { get; set; } = [];
        public ICollection<ComponentCompatibility> CompatibleToComponents { get; set; } = [];
        public ICollection<ComponentPrice> Prices { get; set; } = [];
        public ICollection<ComponentReview> Reviews { get; set; } = [];
    }
}
