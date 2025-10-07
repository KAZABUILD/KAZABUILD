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
    [JsonDerivedType(typeof(GetCoolerSocketSubComponentDto), "CoolerSocket")]
    [JsonDerivedType(typeof(GetIntegratedGraphicsSubComponentDto), "IntegratedGraphics")]
    [JsonDerivedType(typeof(GetM2SlotSubComponentDto), "M2Slot")]
    [JsonDerivedType(typeof(GetOnboardEthernetSubComponentDto), "OnboardEthernet")]
    [JsonDerivedType(typeof(GetPCIeSlotSubComponentDto), "PCIeSlot")]
    [JsonDerivedType(typeof(GetPortSubComponentDto), "Port")]
    public abstract class GetBaseSubComponentDto
    {
        //Filter By fields
        public List<string>? Name { get; set; }

        public List<SubComponentType>? Type { get; set; }

        //Paging related fields
        public bool Paging = false;

        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int? Page { get; set; }

        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int? PageLength { get; set; }

        //Query search string
        public string? Query { get; set; } = "";

        //Sorting related fields
        public string? OrderBy { get; set; }

        public string SortDirection { get; set; } = "asc";
    }
}
