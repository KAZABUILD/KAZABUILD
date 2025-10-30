namespace KAZABUILD.Application.DTOs.Users.UserActivity
{
    public class UserActivityResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public string? ActivityType { get; set; }

        public Guid? TargetId { get; set; }

        public DateTime? Timestamp { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
