namespace KAZABUILD.Application.DTOs.Users.UserGuide
{
    public class UserGuideResponseDto
    {
        public Guid? Id { get; set; }

        public string? Title { get; set; }

        public string? Text { get; set; }

        public string? Author { get; set; }

        public string? Category { get; set; }

        public decimal? TimeToRead { get; set; }

        public DateTime? PostedAt { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
