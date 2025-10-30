using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing a post that was posted by a user to the forum.
    /// </summary>
    public class ForumPost
    {
        //Forum Post fields
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? Creator { get; set; } = default!;

        public ICollection<UserComment> Comments { get; set; } = [];
        public ICollection<Image> Images { get; set; } = [];
    }
}
