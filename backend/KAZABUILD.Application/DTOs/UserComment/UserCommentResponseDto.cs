namespace KAZABUILD.Application.DTOs.UserComment
{
    public class UserCommentResponseDto
    {
        public Guid? Id { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
