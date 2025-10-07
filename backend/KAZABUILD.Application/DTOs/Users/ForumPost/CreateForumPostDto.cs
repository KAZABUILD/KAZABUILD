using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.ForumPost
{
    public class CreateForumPostDto
    {
        /// <summary>
        /// Id of the user who created the post.
        /// </summary>
        [Required]
        public Guid CreatorId { get; set; } = default!;

        /// <summary>
        /// Content of the post.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string Content { get; set; } = default!;

        /// <summary>
        /// Title of the post.
        /// </summary>
        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        /// <summary>
        /// Forum topic in which the message was posted.
        /// Topics are created on the frontend side.
        /// </summary>
        [Required]
        [MaxLength(50, ErrorMessage = "Topic cannot be longer than 50 characters!")]
        public string Topic { get; set; } = default!;

        /// <summary>
        /// Date of the user posting to the forum.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime PostedAt { get; set; } = DateTime.UtcNow;
    }
}
