using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserFollow
{
    public class UpdateUserFollowDto
    {
        /// <summary>
        /// When the user followed.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? FollowedAt { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
