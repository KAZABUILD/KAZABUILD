using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KAZABUILD.Application.DTOs.Components.ComponentReview
{
    public class CreateComponentReviewDto
    {
        /// <summary>
        /// Website url of the website the review is from.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid source URL!")]
        public string SourceUrl { get; set; } = default!;

        /// <summary>
        /// Name of the website/person that reviewed the component.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Reviewer Name cannot be longer than 50 characters!")]
        public string ReviewerName { get; set; } = default!;

        /// <summary>
        /// Id of the component the review is for.
        /// </summary>
        [Required]
        public Guid ComponentId { get; set; } = default!;

        /// <summary>
        /// Date when the review was fetched from the website.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime FetchedAt { get; set; } = default!;

        /// <summary>
        /// Date when the review was created.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime CreatedAt { get; set; } = default!;

        /// <summary>
        /// Rating given in the review on a scale 0-100 (e.g. 1/5 == 20/100).
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Rating must be between 0 and 100")]
        public decimal Rating { get; set; } = default!;

        /// <summary>
        /// Text content of the review.
        /// </summary>
        [Required]
        [StringLength(1000, ErrorMessage = "Review Text cannot be longer than 1000 characters!")]
        public string ReviewText { get; set; } = default!;
    }
}
