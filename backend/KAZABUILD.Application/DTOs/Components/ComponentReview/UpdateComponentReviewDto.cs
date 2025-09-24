using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentReview
{
    public class UpdateComponentReviewDto
    {
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string? SourceUrl { get; set; }

        [StringLength(50, ErrorMessage = "Reviewer Name cannot be longer than 50 characters!")]
        public string? ReviewerName { get; set; }

        public Guid? ComponentId { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? FetchedAt { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? CreatedAt { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal? Rating { get; set; }

        [StringLength(1000, ErrorMessage = "Review Text cannot be longer than 4 characters!")]
        public string? ReviewText { get; set; } = default!;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
