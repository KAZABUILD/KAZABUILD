using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserCommentInteraction
{
    public class UpdateUserCommentInteractionDto
    {
        /// <summary>
        /// Whether the user Liked the Comment.
        /// </summary>
        public bool? IsLiked { get; set; }

        /// <summary>
        /// Whether the user Disliked the Comment.
        /// </summary>
        public bool? IsDisliked { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
