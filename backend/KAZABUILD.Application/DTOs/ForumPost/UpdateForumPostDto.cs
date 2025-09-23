using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.ForumPost
{
    public class UpdateForumPostDto
    {
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string? Content { get; set; }

        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string? Title { get; set; }

        [MaxLength(50, ErrorMessage = "Topic cannot be longer than 50 characters!")]
        public string? Topic { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
