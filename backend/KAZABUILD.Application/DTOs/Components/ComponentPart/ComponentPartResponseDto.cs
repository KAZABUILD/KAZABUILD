using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentPart
{
    public class ComponentPartResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? ComponentId { get; set; }

        public Guid? SubComponentId { get; set; }

        public int? Amount { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
