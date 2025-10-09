using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentCompatibility
{
    public class ComponentCompatibilityResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? ComponentId { get; set; }

        public Guid? CompatibleComponentId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
