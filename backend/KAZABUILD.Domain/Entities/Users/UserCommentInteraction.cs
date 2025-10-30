using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Represents Interactions that a user can have with a Comment.
    /// </summary>
    public class UserCommentInteraction
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the User that Interacted with the Comment.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the Comment the user Interacted with.
        /// </summary>
        [Required]
        public Guid UserCommentId { get; set; } = default!;

        /// <summary>
        /// Whether the user Liked the Comment.
        /// </summary>
        [Required]
        public bool IsLiked { get; set; } = false;

        /// <summary>
        /// Whether the user Disliked the Comment.
        /// </summary>
        [Required]
        public bool IsDisliked { get; set; } = false;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public UserComment? UserComment { get; set; } = default!;
    }
}
