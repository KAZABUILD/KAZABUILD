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
    /// <summary>
    /// Only used for polymorphism and inheritance by other component classes.
    /// </summary>
    [JsonDerivedType(typeof(CreateCaseComponentDto), "Case")]
    [JsonDerivedType(typeof(CreateCaseFanComponentDto), "CaseFan")]
    [JsonDerivedType(typeof(CreateCoolerComponentDto), "Cooler")]
    [JsonDerivedType(typeof(CreateCPUComponentDto), "CPU")]
    [JsonDerivedType(typeof(CreateGPUComponentDto), "GPU")]
    [JsonDerivedType(typeof(CreateMemoryComponentDto), "Memory")]
    [JsonDerivedType(typeof(CreateMonitorComponentDto), "Monitor")]
    [JsonDerivedType(typeof(CreateMotherboardComponentDto), "Motherboard")]
    [JsonDerivedType(typeof(CreatePowerSupplyComponentDto), "PowerSupply")]
    [JsonDerivedType(typeof(CreateStorageComponentDto), "Storage")]
    public abstract class CreateBaseComponentDto
    {
        /// <summary>
        /// The Component's name.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Who created the Component.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Manufacturer cannot be longer than 50 characters!")]
        public string Manufacturer { get; set; } = default!;

        /// <summary>
        /// The release date of the Component. Often just the year.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? Release { get; set; }

        /// <summary>
        /// Type of the Component. Used to distinguish between inherited classes in the database.
        /// </summary>
        [Required]
        [EnumDataType(typeof(ComponentType))]
        public ComponentType Type { get; set; }
    }
}
