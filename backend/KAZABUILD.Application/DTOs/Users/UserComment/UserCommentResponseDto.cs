namespace KAZABUILD.Application.DTOs.Users.UserComment
{
    public class UserCommentResponseDto
    {
        public Guid? Id { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
