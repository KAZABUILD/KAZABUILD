using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildInteraction
{
    public class CreateBuildInteractionDto
    {
        /// <summary>
        /// Id of the User that Interacted with the Build.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the Build the user Interacted with.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Whether the user Wishlisted the Build.
        /// </summary>
        [Required]
        public bool IsWishlisted { get; set; } = false;

        /// <summary>
        /// Whether the user Liked the Build.
        /// </summary>
        [Required]
        public bool IsLiked { get; set; } = false;

        /// <summary>
        /// User's Rating for the Build on the scale of 0-100.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Amount must be between 0 and 100!")]
        public int Rating { get; set; } = default!;

        /// <summary>
        /// User's Note for the Build.
        /// </summary>
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? UserNote { get; set; }
    }
}
