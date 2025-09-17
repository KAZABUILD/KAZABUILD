using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class UserFollow
    {
        //Follow fields
        public Guid Id { get; set; }

        public Guid FollowerId { get; set; }

        public Guid FollowedId { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        public string? Note { get; set; }

        //Database relationships
        public User? Follower { get; set; } = default!;
        public User? Followed { get; set; } = default!;
    }
}
