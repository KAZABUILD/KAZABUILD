namespace KAZABUILD.Application.DTOs.Builds.BuildComponent
{
    public class BuildComponentResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? BuildId { get; set; }

        public Guid? ComponentId { get; set; }

        public int? Quantity { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
