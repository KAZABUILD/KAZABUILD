using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.BuildInteraction
{
    public class UpdateBuildInteractionDto
    {
        /// <summary>
        /// Whether the user Wishlisted the Build.
        /// </summary>
        public bool? IsWishlisted { get; set; }

        /// <summary>
        /// Whether the user Liked the Build.
        /// </summary>
        public bool? IsLiked { get; set; }

        /// <summary>
        /// User's Rating for the Build on the scale of 0-100.
        /// </summary>
        [Range(0, 100, ErrorMessage = "Amount must be between 0 and 100!")]
        public int? Rating { get; set; }

        /// <summary>
        /// User's Note for the Build.
        /// </summary>
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? UserNote { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
