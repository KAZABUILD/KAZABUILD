using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentColor
{
    public class ComponentColorResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? ComponentId { get; set; }

        public string? ColorCode { get; set; }

        public string? ColorName { get; set; }

        public bool? IsAvailable { get; set; }

        public decimal? AdditionalPrice { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
