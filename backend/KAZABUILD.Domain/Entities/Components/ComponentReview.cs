using KAZABUILD.Domain.Entities.Components.Components;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Domain.Entities.Components
{
    public class ComponentReview
    {
        //Component review fields
        [Key]
        public Guid Id { get; set; }

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string SourceUrl { get; set; } = default!;

        [Required]
        public Guid ComponentId { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? FetchedAt { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? CreatedAt { get; set; } = default!;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal Rating { get; set; } = default!;

        [Required]
        [StringLength(1000, ErrorMessage = "Review Text cannot be longer than 4 characters!")]
        public string ReviewText { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public BaseComponent Component { get; set; } = default!;
    }
}
