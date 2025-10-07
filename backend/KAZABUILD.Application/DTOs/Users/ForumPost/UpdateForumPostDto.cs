using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.ForumPost
{
    public class UpdateForumPostDto
    {
        /// <summary>
        /// Content of the post.
        /// </summary>
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string? Content { get; set; }

        /// <summary>
        /// Title of the post.
        /// </summary>
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        /// <summary>
        /// Forum topic in which the message was posted.
        /// Topics are created on the frontend side.
        /// </summary>
        [MaxLength(50, ErrorMessage = "Topic cannot be longer than 50 characters!")]
        public string? Topic { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
