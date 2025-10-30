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
        /// <summary>
        /// Whether the paging should be used.
        /// </summary>
        public bool Paging = false;

        /// <summary>
        /// Which page should be gotten if paging enabled.
        /// </summary>
        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int? Page { get; set; }

        /// <summary>
        /// How many objects should be in the response if paging enabled.
        /// </summary>
        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int? PageLength { get; set; }

        //Query search string
        /// <summary>
        /// Query string with words to be looked for in the search.
        /// </summary>
        public string? Query { get; set; } = "";

        //Sorting related fields
        /// <summary>
        /// By which should the return items be sorted by.
        /// </summary>
        public string? OrderBy { get; set; }

        /// <summary>
        /// Sort direction - either asc or desc.
        /// </summary>
        public string SortDirection { get; set; } = "asc";
    }
}
