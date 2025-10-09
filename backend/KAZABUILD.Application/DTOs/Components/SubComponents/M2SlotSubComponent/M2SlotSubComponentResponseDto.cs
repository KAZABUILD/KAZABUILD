using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent
{
    public class M2SlotSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? Size { get; set; }

        public string? KeyType { get; set; }

        public string? Interface { get; set; }
    }
}
