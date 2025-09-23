namespace KAZABUILD.Application.DTOs.UserPreference
{
    public class UserPreferenceResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
