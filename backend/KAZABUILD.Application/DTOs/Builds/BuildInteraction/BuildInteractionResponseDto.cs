namespace KAZABUILD.Application.DTOs.Builds.BuildInteraction
{
    public class BuildInteractionResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public Guid? BuildId { get; set; }

        public bool? IsWishlisted { get; set; }

        public bool? IsLiked { get; set; }

        public int? Rating { get; set; }

        public string? UserNote { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
