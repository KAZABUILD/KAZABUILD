using KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent;
using KAZABUILD.Domain.Enums;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    /// <summary>
    /// Only used for polymorphism and inheritance by other subComponent classes.
    /// </summary>
    [JsonDerivedType(typeof(CoolerSocketSubComponentResponseDto), "CoolerSocket")]
    [JsonDerivedType(typeof(IntegratedGraphicsSubComponentResponseDto), "IntegratedGraphics")]
    [JsonDerivedType(typeof(M2SlotSubComponentResponseDto), "M2Slot")]
    [JsonDerivedType(typeof(OnboardEthernetSubComponentResponseDto), "OnboardEthernet")]
    [JsonDerivedType(typeof(PCIeSlotSubComponentResponseDto), "PCIeSlot")]
    [JsonDerivedType(typeof(PortSubComponentResponseDto), "Port")]
    public class BaseSubComponentResponseDto
    {
        public Guid? Id { get; set; }

        public string? Name { get; set; }

        public SubComponentType? Type { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
