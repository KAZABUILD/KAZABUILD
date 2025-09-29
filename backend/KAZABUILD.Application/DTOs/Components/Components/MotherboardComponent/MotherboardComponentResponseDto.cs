using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class MotherboardComponentResponseDto : BaseComponentResponseDto
    {
        public string? SocketType { get; set; }

        public string? FormFactor { get; set; }

        public string? ChipsetType { get; set; }

        public string? RAMType { get; set; }

        public decimal? RAMSlotsAmount { get; set; }
    }
}
