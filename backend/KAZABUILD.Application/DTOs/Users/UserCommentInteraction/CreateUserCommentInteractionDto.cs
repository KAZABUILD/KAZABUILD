using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserCommentInteraction
{
    public class CreateUserCommentInteractionDto
    {
        /// <summary>
        /// Id of the User that Interacted with the Comment.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the Comment the user Interacted with.
        /// </summary>
        [Required]
        public Guid UserCommentId { get; set; } = default!;

        /// <summary>
        /// Whether the user Liked the Comment.
        /// </summary>
        [Required]
        public bool IsLiked { get; set; } = false;

        /// <summary>
        /// Whether the user Disliked the Comment.
        /// </summary>
        [Required]
        public bool IsDisliked { get; set; } = false;
    }
}
