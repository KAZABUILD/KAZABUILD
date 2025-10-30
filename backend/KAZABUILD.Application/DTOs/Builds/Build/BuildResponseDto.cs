using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Builds.Build
{
    public class BuildResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public string? Name { get; set; }

        public string? Description { get; set; }

        public BuildStatus? Status { get; set; } = BuildStatus.DRAFT;

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
