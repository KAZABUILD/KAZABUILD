using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFollow
{
    public class UserFollowResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? FollowerId { get; set; }

        public Guid? FollowedId { get; set; }

        public DateTime? FollowedAt { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
