using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Application.DTOs.Builds.Tag;

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

        // Additional fields for explore builds page
        public List<BaseComponentResponseDto>? Components { get; set; }
        public List<string>? Tags { get; set; }
        public double? AverageRating { get; set; }
        public int? RatingsCount { get; set; }
        public double? UserRating { get; set; }
        public string? AuthorName { get; set; }
        public Guid? AuthorImageId { get; set; }
        public string? ImageUrl { get; set; }
    }
}
