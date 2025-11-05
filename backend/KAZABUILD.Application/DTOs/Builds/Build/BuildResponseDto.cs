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

        /// <summary>
        /// Average rating for this build (0-100 scale)
        /// </summary>
        public double? AverageRating { get; set; }

        /// <summary>
        /// Number of ratings submitted for this build
        /// </summary>
        public int? RatingsCount { get; set; }

        /// <summary>
        /// Current user's rating for this build (0-100 scale), if any
        /// </summary>
        public int? UserRating { get; set; }
    }
}
