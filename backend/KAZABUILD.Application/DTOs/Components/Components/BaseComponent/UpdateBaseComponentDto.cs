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
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.Components.BaseComponent
{
    [JsonDerivedType(typeof(UpdateCaseComponentDto), "Case")]
    [JsonDerivedType(typeof(UpdateCaseFanComponentDto), "CaseFan")]
    [JsonDerivedType(typeof(UpdateCoolerComponentDto), "Cooler")]
    [JsonDerivedType(typeof(UpdateCPUComponentDto), "CPU")]
    [JsonDerivedType(typeof(UpdateGPUComponentDto), "GPU")]
    [JsonDerivedType(typeof(UpdateMemoryComponentDto), "Memory")]
    [JsonDerivedType(typeof(UpdateMonitorComponentDto), "Monitor")]
    [JsonDerivedType(typeof(UpdateMotherboardComponentDto), "Motherboard")]
    [JsonDerivedType(typeof(UpdatePowerSupplyComponentDto), "PowerSupply")]
    [JsonDerivedType(typeof(UpdateStorageComponentDto), "Storage")]
    public abstract class UpdateBaseComponentDto
    {
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string? Name { get; set; }

        [StringLength(50, ErrorMessage = "Manufacturer cannot be longer than 50 characters!")]
        public string? Manufacturer { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? Release { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
