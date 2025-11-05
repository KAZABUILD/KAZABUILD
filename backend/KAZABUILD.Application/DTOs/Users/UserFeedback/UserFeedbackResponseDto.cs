namespace KAZABUILD.Application.DTOs.Users.UserFeedback
{
    public class UserFeedbackResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public string? Feedback { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
