using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFollow
{
    public class CreateUserFollowDto
    {
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
    }
}
