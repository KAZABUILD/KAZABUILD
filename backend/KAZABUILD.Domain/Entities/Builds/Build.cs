using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Builds
{
    /// <summary>
    /// Combination of components that create a PC Build on the website.
    /// Can be created either by user, administration or can be generated.
    /// </summary>
    public class Build
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the User that created the Build.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Name given to the Build by the user.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Description of the Build written by the user.
        /// </summary>
        [Required]
        [StringLength(5000, ErrorMessage = "Description cannot be longer than 5000 characters!")]
        public string Description { get; set; } = default!;

        /// <summary>
        /// Current status of the Build.
        /// Determines where on the website the Build is visible
        /// </summary>
        [Required]
        [EnumDataType(typeof(BuildStatus))]
        public BuildStatus Status { get; set; } = BuildStatus.DRAFT;

        /// <summary>
        /// Date when the user Published the Build.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? PublishedAt { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public ICollection<BuildComponent> Components { get; set; } = [];
        public ICollection<BuildInteraction> Interactions { get; set; } = [];
        public ICollection<Tag> Tags { get; set; } = [];
        public ICollection<BuildTag> BuildTags { get; set; } = [];
        public ICollection<UserComment> Comments { get; set; } = [];
        public ICollection<Image> Images { get; set; } = [];
        public ICollection<UserReport> UserReports { get; set; } = [];
    }
}
