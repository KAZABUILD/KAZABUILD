using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.DTOs.Users.UserComment
{
    public class UserCommentResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public string? Content { get; set; }

        public DateTime? PostedAt { get; set; }

        public Guid? ParentCommentId { get; set; }

        public CommentTargetType? CommentTargetType { get; set; }

        public Guid? TargetId { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
