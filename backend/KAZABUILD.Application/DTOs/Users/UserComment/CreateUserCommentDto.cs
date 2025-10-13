using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserComment
{
    public class CreateUserCommentDto
    {
        /// <summary>
        /// Id of the User that posted the Comment.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// The Contents of the Comment.
        /// </summary>
        [Required]
        [MaxLength(1000, ErrorMessage = "Content cannot be longer than 1000 characters!")]
        public string Content { get; set; } = default!;

        /// <summary>
        /// When the Comment was Posted.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime PostedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Id of another Comment that this Comment is replying to.
        /// Null if standalone. 
        /// </summary>
        public Guid? ParentCommentId { get; set; }

        /// <summary>
        /// Type of the model being Targeted by the Comment.
        /// </summary>
        [Required]
        [EnumDataType(typeof(CommentTargetType))]
        public CommentTargetType CommentTargetType { get; set; } = default!;

        /// <summary>
        /// Id of the object this Comment is replying to.
        /// Which object it's applied to depends on the CommentTargetType set.
        /// </summary>
        public Guid? TargetId { get; set; }
    }
}
