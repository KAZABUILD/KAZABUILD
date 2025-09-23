using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    public class UserFollow
    {
        //Follow fields
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid FollowerId { get; set; } = default!;

        [Required]
        public Guid FollowedId { get; set; } = default!;

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
