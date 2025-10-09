using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Builds
{
    /// <summary>
    /// Represents a connection between a Build and a Tag.
    /// </summary>
    public class BuildTag
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the Build the Tag describes.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Id of the Tag describing the Build.
        /// </summary>
        [Required]
        public Guid TagId { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public Build? Build { get; set; } = default!;
        public Tag? Tag { get; set; } = default!;
    }
}
