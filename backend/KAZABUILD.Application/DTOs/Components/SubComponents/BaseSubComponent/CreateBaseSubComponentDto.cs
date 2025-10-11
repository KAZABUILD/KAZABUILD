using KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent;
using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    [JsonDerivedType(typeof(CreateCoolerSocketSubComponentDto), "CoolerSocket")]
    [JsonDerivedType(typeof(CreateIntegratedGraphicsSubComponentDto), "IntegratedGraphics")]
    [JsonDerivedType(typeof(CreateM2SlotSubComponentDto), "M2Slot")]
    [JsonDerivedType(typeof(CreateOnboardEthernetSubComponentDto), "OnboardEthernet")]
    [JsonDerivedType(typeof(CreatePCIeSlotSubComponentDto), "PCIeSlot")]
    [JsonDerivedType(typeof(CreatePortSubComponentDto), "Port")]
    public abstract class CreateBaseSubComponentDto
    {
        /// <summary>
        /// The name of the SubComponent. 
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Type of the SubComponent. Used to distinguish between inherited classes in the database.
        /// </summary>
        [Required]
        [EnumDataType(typeof(SubComponentType))]
        public SubComponentType Type { get; set; }
    }
}
