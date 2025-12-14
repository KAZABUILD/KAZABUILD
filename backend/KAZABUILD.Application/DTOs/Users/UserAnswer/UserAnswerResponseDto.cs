using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserAnswer
{
    public class UserAnswerResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public Guid? UserPreferenceAnswerId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
