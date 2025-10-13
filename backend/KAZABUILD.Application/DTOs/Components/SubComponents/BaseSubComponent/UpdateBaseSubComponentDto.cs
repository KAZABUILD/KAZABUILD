using KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent
{
    [JsonDerivedType(typeof(UpdateCoolerSocketSubComponentDto), "CoolerSocket")]
    [JsonDerivedType(typeof(UpdateIntegratedGraphicsSubComponentDto), "IntegratedGraphics")]
    [JsonDerivedType(typeof(UpdateM2SlotSubComponentDto), "M2Slot")]
    [JsonDerivedType(typeof(UpdateOnboardEthernetSubComponentDto), "OnboardEthernet")]
    [JsonDerivedType(typeof(UpdatePCIeSlotSubComponentDto), "PCIeSlot")]
    [JsonDerivedType(typeof(UpdatePortSubComponentDto), "Port")]
    public abstract class UpdateBaseSubComponentDto
    {
        /// <summary>
        /// The name of the SubComponent. 
        /// </summary>
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string? Name { get; set; }

        /// <summary>
        /// Type of the SubComponent. Used to distinguish between inherited classes in the database.
        /// </summary>
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
