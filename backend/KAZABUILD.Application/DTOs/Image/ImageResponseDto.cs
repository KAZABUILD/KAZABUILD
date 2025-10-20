using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class ImageResponseDto
    {
        public Guid Id { get; set; }

        public ImageLocationType? LocationType { get; set; }

        public Guid? UserId { get; set; }

        public Guid? BuildId { get; set; }

        public Guid? ForumPostId { get; set; }

        public Guid? ComponentId { get; set; }

        public Guid? SubComponentId { get; set; }

        public Guid? UserCommentId { get; set; }

        public string? Name { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
