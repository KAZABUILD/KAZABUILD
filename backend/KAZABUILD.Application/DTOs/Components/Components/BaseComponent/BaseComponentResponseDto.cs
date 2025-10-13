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

using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    /// <summary>
    /// Only used for polymorphism and inheritance by other component classes.
    /// </summary>
    [JsonDerivedType(typeof(CaseComponentResponseDto), "Case")]
    [JsonDerivedType(typeof(CaseFanComponentResponseDto), "CaseFan")]
    [JsonDerivedType(typeof(CoolerComponentResponseDto), "Cooler")]
    [JsonDerivedType(typeof(CPUComponentResponseDto), "CPU")]
    [JsonDerivedType(typeof(GPUComponentResponseDto), "GPU")]
    [JsonDerivedType(typeof(MemoryComponentResponseDto), "Memory")]
    [JsonDerivedType(typeof(MonitorComponentResponseDto), "Monitor")]
    [JsonDerivedType(typeof(MotherboardComponentResponseDto), "Motherboard")]
    [JsonDerivedType(typeof(PowerSupplyComponentResponseDto), "PowerSupply")]
    [JsonDerivedType(typeof(StorageComponentResponseDto), "Storage")]
    public abstract class BaseComponentResponseDto
    {
        public Guid? Id { get; set; }

        public string? Name { get; set; }

        public string? Manufacturer { get; set; }

        public DateTime? Release { get; set; }

        public ComponentType? Type { get; set; }

        public int? NumberOfParts { get; set; }

        public DateTime? DatabaseEntryAt { get; set; }

        public DateTime? LastEditedAt { get; set; }

        public string? Note { get; set; }
    }
}
