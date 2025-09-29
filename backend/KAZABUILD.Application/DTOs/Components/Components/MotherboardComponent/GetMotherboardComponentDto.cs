using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class GetMotherboardComponentDto : GetBaseComponentDto
    {
        public List<string>? SocketType { get; set; }

        public List<string>? FormFactor { get; set; }

        public List<string>? ChipsetType { get; set; }

        public List<string>? RAMType { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public decimal? RAMSlotsAmount { get; set; }
    }
}
