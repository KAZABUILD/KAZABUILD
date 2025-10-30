namespace KAZABUILD.Application.DTOs.Components.ComponentReview
{
    public class ComponentReviewResponseDto
    {
        public Guid? Id { get; set; }

        public string? SourceUrl { get; set; }

        public string? ReviewerName { get; set; }

        public Guid? ComponentId { get; set; }

        public DateTime? FetchedAt { get; set; }

        public DateTime? CreatedAt { get; set; }

        public decimal? Rating { get; set; }

        public string? ReviewText { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
