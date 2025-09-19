using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.UserFollow
{
    public class UpdateUserFollowDto
    {
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? FollowedAt { get; set; }
    }
}
