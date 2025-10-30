using KAZABUILD.Application.DTOs.Components.Components.CaseComponent;
using KAZABUILD.Application.DTOs.Components.Components.CaseFanComponent;
using KAZABUILD.Application.DTOs.Components.Components.CoolerComponent;
using KAZABUILD.Application.DTOs.Components.Components.CPUComponent;
using KAZABUILD.Application.DTOs.Components.Components.GPUComponent;
using KAZABUILD.Application.DTOs.Components.Components.MemoryComponent;
using KAZABUILD.Application.DTOs.Components.Components.MonitorComponent;
using KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent;
using KAZABUILD.Application.DTOs.Components.Components.PowerSupplyComponent;
using KAZABUILD.Application.DTOs.Components.Components.StorageComponent;
using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    [JsonDerivedType(typeof(GetCaseComponentDto), "Case")]
    [JsonDerivedType(typeof(GetCaseFanComponentDto), "CaseFan")]
    [JsonDerivedType(typeof(GetCoolerComponentDto), "Cooler")]
    [JsonDerivedType(typeof(GetCPUComponentDto), "CPU")]
    [JsonDerivedType(typeof(GetGPUComponentDto), "GPU")]
    [JsonDerivedType(typeof(GetMemoryComponentDto), "Memory")]
    [JsonDerivedType(typeof(GetMonitorComponentDto), "Monitor")]
    [JsonDerivedType(typeof(GetMotherboardComponentDto), "Motherboard")]
    [JsonDerivedType(typeof(GetPowerSupplyComponentDto), "PowerSupply")]
    [JsonDerivedType(typeof(GetStorageComponentDto), "Storage")]
    public abstract class GetBaseComponentDto
    {
        //Filter By fields
        public List<string>? Name { get; set; }

        public List<string>? Manufacturer { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? ReleaseStart { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? ReleaseEnd { get; set; }

        public List<ComponentType>? Type { get; set; }

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
