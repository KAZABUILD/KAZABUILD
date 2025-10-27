using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class ImageResponseDto
    {
        public Guid Id { get; set; }

        public ImageLocationType? LocationType { get; set; }

        public Guid? TargetId { get; set; }

        public string? Name { get; set; }

        public string? Location { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
