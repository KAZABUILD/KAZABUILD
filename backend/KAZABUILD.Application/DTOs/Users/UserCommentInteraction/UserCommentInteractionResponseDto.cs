namespace KAZABUILD.Application.DTOs.Users.UserCommentInteraction
{
    public class UserCommentInteractionResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? UserId { get; set; }

        public Guid? UserCommentId { get; set; }

        public bool? IsLiked { get; set; }

        public bool? IsDisliked { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
