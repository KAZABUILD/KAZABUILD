using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.ForumPost
{
    public class ForumPostResponseDto
    {
        public Guid Id { get; set; }

        public Guid? CreatorId { get; set; }

        public string? Content { get; set; }

        public string? Title { get; set; }

        public string? Topic { get; set; }

        public DateTime? PostedAt { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
