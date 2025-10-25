namespace KAZABUILD.Application.DTOs.Components.ComponentVariant
{
    public class ComponentVariantResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? ComponentId { get; set; }

        /// <summary>
        /// List of pairs of color codes and names.
        /// </summary>
        public List<Tuple<string, string>>? Colors { get; set; }

        public bool? IsAvailable { get; set; }

        public decimal? AdditionalPrice { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
