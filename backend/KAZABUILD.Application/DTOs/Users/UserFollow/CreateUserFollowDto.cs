using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFollow
{
    public class CreateUserFollowDto
    {
        [Required]
        public Guid FollowerId { get; set; } = default!;

        [Required]
        public Guid FollowedId { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime FollowedAt { get; set; } = default!;
    }
}
