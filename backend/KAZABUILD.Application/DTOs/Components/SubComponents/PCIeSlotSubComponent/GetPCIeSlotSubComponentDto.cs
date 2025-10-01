using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent
{
    public class GetPCIeSlotSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? Gen { get; set; }

        public List<string>? Lanes { get; set; }

        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10")]
        public int? QuantityStart { get; set; }

        [Range(1, 10, ErrorMessage = "Quantity must be between 1 and 10")]
        public int? QuantityStartEnd { get; set; }
    }
}
