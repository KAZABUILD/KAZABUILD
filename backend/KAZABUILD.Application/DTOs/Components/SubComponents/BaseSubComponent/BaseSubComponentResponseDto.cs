using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    public class BaseSubComponentResponseDto
    {
        public Guid? Id { get; set; }

        public SubComponentType? Type { get; set; }

        public int? NumberOfParts { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
