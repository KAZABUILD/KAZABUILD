using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentReview
{
    public class UpdateComponentReviewDto
    {
        /// <summary>
        /// Website url of the website the review is from.
        /// </summary>
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string? SourceUrl { get; set; }

        /// <summary>
        /// Name of the website/person that reviewed the component.
        /// </summary>
        [StringLength(50, ErrorMessage = "Reviewer Name cannot be longer than 50 characters!")]
        public string? ReviewerName { get; set; }

        /// <summary>
        /// Id of the component the review is for.
        /// </summary>
        public Guid? ComponentId { get; set; }

        /// <summary>
        /// Date when the review was fetched from the website.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? FetchedAt { get; set; }

        /// <summary>
        /// Date when the review was created.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? CreatedAt { get; set; }

        /// <summary>
        /// Rating given in the review on a scale 0-100 (e.g. 1/5 == 20/100).
        /// </summary>
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal? Rating { get; set; }

        /// <summary>
        /// Text content of the review.
        /// </summary>
        [StringLength(1000, ErrorMessage = "Review Text cannot be longer than 1000 characters!")]
        public string? ReviewText { get; set; } = default!;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
