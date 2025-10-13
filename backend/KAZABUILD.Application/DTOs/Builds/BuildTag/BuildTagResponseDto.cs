namespace KAZABUILD.Application.DTOs.Builds.BuildTag
{
    public class BuildTagResponseDto
    {
        public Guid? Id { get; set; }

        public Guid BuildId { get; set; }

        public Guid TagId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
