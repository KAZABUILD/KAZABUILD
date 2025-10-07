using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing which user follows who.
    /// </summary>
    public class UserFollow
    {
        //Follow fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the user that is following.
        /// </summary>
        [Required]
        public Guid FollowerId { get; set; } = default!;

        /// <summary>
        /// Id of the user being followed.
        /// </summary>
        [Required]
        public Guid FollowedId { get; set; } = default!;

        /// <summary>
        /// When the user followed.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime FollowedAt { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? Follower { get; set; } = default!;
        public User? Followed { get; set; } = default!;
    }
}
