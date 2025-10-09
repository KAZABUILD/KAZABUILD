using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model storing comments left by users.
    /// </summary>
    public class UserComment
    {
        //User Comment fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the user that posted the comment.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// The contents pf the comment.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string Content { get; set; } = default!;

        /// <summary>
        /// Id of another comment that this comment is replying to.
        /// Null if standalone. 
        /// </summary>
        public Guid? ParentCommentId { get; set; }

        /// <summary>
        /// Type of the model being target by the comment.
        /// </summary>
        [Required]
        [EnumDataType(typeof(CommentTargetType))]
        public CommentTargetType CommentTargetType { get; set; } = default!;

        //Possible references, only one should ever be set at a time
        /// <summary>
        /// Id of the Forum Post this comment is replying to.
        /// Can be null as a comment should be left under only one object.
        /// </summary>
        public Guid? ForumPostId { get; set; }

        /// <summary>
        /// Id of the Build this comment is replying to.
        /// Can be null as a comment should be left under only one object.
        /// </summary>
        public Guid? BuildId { get; set; }

        /// <summary>
        /// Id of the forum post this comment is replying to.
        /// Can be null as a comment should be left under only one object.
        /// </summary>
        public Guid? ComponentId { get; set; }

        /// <summary>
        /// Id of the Component Review this comment is replying to.
        /// Can be null as a comment should be left under only one object.
        /// </summary>
        public Guid? ComponentReviewId { get; set; }

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
        public BaseComponent? Component { get; set; } = default!;
        public ComponentReview? ComponentReview { get; set; } = default!;
        public Build? Build { get; set; } = default!;
    }
}
