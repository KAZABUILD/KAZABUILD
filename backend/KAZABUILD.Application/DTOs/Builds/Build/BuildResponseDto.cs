using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.Build
{
    public class BuildResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public string? Name { get; set; }

        public string? Description { get; set; }

        public BuildStatus? Status { get; set; }

        public DateTime? PublishedAt { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
