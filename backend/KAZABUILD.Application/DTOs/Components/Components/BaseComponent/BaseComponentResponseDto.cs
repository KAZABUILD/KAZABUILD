using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    public class BaseComponentResponseDto
    {
        public Guid? Id { get; set; }

        public string? Name { get; set; }

        public string? Manufacturer { get; set; }

        public DateTime? Release { get; set; }

        public ComponentType? Type { get; set; }

        public int? NumberOfParts { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
