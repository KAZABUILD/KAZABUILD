using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class UserComment
    {
        //User Comment fields
        [Key]
        public Guid Id { get; set; } = default!;

        [Required]
        public Guid UserId { get; set; } = default!;

        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 50 characters!")]
        public string Content { get; set; } = default!;

        public Guid? ParentCommentId { get; set; }

        [Required]
        public CommentTargetType CommentTargetType { get; set; } = default!;

        //Possible references, only one should ever be set at a time
        public Guid? ForumPostId { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public UserComment? ParentComment { get; set; } = default!;
        public ICollection<UserComment> ChildComments { get; set; } = [];
        public ForumPost? ForumPost { get; set; } = default!;
    }
}
