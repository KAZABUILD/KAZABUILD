using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Builds
{
    /// <summary>
    /// Tag that can be applied to a pc build to further describe and categorize it.
    /// </summary>
    public class Tag
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// The Name of the Tag.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Explanation of what the Tag is Describing.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Description cannot be longer than 500 characters!")]
        public string Description { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<BuildTag> Builds { get; set; } = [];
    }
}
