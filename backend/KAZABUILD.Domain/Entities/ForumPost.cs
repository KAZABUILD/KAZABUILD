using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class ForumPost
    {
        //Forum Post fields
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid CreatorId { get; set; } = default!;

        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string Content { get; set; } = default!;

        [Required]
        [MaxLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        public string Title { get; set; } = default!;

        [Required]
        [MaxLength(50, ErrorMessage = "Topic cannot be longer than 50 characters!")]
        public string Topic { get; set; } = default!;

        //Additional database information
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

        public ICollection<UserComment> UserComments { get; set; } = [];
    }
}
