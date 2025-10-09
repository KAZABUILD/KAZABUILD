using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Color
{
    public class ColorResponseDto
    {
        public string? ColorCode { get; set; }

        public string? ColorName { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
