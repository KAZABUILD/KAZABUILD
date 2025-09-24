using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class ComponentPriceResponseDto
    {
        public Guid? Id { get; set; }

        public string? SourceUrl { get; set; }

        public Guid? ComponentId { get; set; }

        public string? VendorName { get; set; }

        public DateTime? FetchedAt { get; set; }

        public decimal? Price { get; set; }

        public string? Currency { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
