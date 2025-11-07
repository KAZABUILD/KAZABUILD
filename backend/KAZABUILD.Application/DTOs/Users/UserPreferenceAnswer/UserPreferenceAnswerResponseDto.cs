using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreferenceAnswer
{
    public class UserPreferenceAnswerResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserPreferenceId { get; set; }

        public string? Answer { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
