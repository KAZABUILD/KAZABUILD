using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Components.SubComponents;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    /// <summary>
    /// Model storing an image attached to an object or embedded in text.
    /// </summary>
    public class Image
    {
        [Key]
        public Guid Id {  get; set; }

        /// <summary>
        /// Type of location of the image.
        /// </summary>
        [Required]
        [EnumDataType(typeof(ImageLocationType))]
        public ImageLocationType LocationType { get; set; } = default!;

        //Possible references, only one should ever be set at a time
        /// <summary>
        /// Id of the User Profile this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? UserId { get; set; }

        /// <summary>
        /// Id of the Build this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? BuildId { get; set; }

        /// <summary>
        /// Id of the Forum Post this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? ForumPostId { get; set; }

        /// <summary>
        /// Id of the Comment this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? ComponentId { get; set; }

        /// <summary>
        /// Id of the SubComment this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? SubComponentId { get; set; }

        /// <summary>
        /// Id of the User Comment this Image is in.
        /// Can be null as a Image should be stored for only one entity.
        /// </summary>
        public Guid? UserCommentId { get; set; }

        /// <summary>
        /// Name which is used for the image in the html.
        /// Can be used to match the returned images to their proper name.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Location where the image is saved in the storage.
        /// Includes the name of the folder it's saved in, (e.g., wwwroot/filename.png).
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        [MinLength(5, ErrorMessage = "Location must be at least 5 characters long!")]
        public string Location { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public ForumPost? ForumPost { get; set; } = default!;
        public BaseComponent? Component { get; set; } = default!;
        public BaseSubComponent? SubComponent { get; set; } = default!;
        public UserComment? UserComment { get; set; } = default!;
        public Build? Build { get; set; } = default!;
    }
}
