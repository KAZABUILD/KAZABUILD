using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserComment
{
    public class UpdateUserCommentDto
    {
        /// <summary>
        /// The Contents of the Comment.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string? Content { get; set; }

        /// <summary>
        /// When the Comment was Posted.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime? PostedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
