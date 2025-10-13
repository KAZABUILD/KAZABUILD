namespace KAZABUILD.Application.DTOs.Components.SubComponentPart
{
    public class SubComponentPartResponseDto
    {
        public Guid? Id { get; set; }

        public Guid? MainSubComponentId { get; set; }

        public Guid? SubComponentId { get; set; }

        public int? Amount { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
