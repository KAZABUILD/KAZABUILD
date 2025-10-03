using Azure;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
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
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;
using Linq = System.Linq;

namespace KAZABUILD.API.Controllers.Components
{
    /// <summary>
    /// Controller for Component related endpoints.
    /// Allows for polymorphic handling of the Components class.
    /// The BaseComponent class and its dto's can be treated as all its derived classes.
    /// The classes are: Case, CaseFan, Cooler, CPU, GPU, Memory, Monitor, Motherboard, PowerSupply, Storage.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class ComponentController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new Component for administration.
        /// The class created is based on the provide type.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponent([FromBody] CreateBaseComponentDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Declare the Component variable
            BaseComponent component;

            //Return an invalid response if try/catch statement catches a type assignment error
            try
            {
                //Create a component to add
                component = dto switch
                {
                    CreateCaseComponentDto caseDto => new CaseComponent
                    {
                        Name = caseDto.Name,
                        Manufacturer = caseDto.Manufacturer,
                        Release = caseDto.Release,
                        Type = caseDto.Type,
                        FormFactor = caseDto.FormFactor,
                        PowerSupplyShrouded = caseDto.PowerSupplyShrouded,
                        PowerSupplyAmount = caseDto.PowerSupplyAmount,
                        HasTransparentSidePanel = caseDto.HasTransparentSidePanel,
                        SidePanelType = caseDto.SidePanelType,
                        MaxVideoCardLength = caseDto.MaxVideoCardLength,
                        MaxCPUCoolerHeight = caseDto.MaxCPUCoolerHeight,
                        Internal35BayAmount = caseDto.Internal35BayAmount,
                        Internal25BayAmount = caseDto.Internal25BayAmount,
                        External35BayAmount = caseDto.External35BayAmount,
                        External525BayAmount = caseDto.External525BayAmount,
                        ExpansionSlotAmount = caseDto.ExpansionSlotAmount,
                        Dimensions = caseDto.Dimensions,
                        Weight = caseDto.Weight,
                        SupportsRearConnectingMotherboard = caseDto.SupportsRearConnectingMotherboard,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateCaseFanComponentDto caseFanDto => new CaseFanComponent
                    {
                        Name = caseFanDto.Name,
                        Manufacturer = caseFanDto.Manufacturer,
                        Release = caseFanDto.Release,
                        Type = caseFanDto.Type,
                        Size = caseFanDto.Size,
                        Quantity = caseFanDto.Quantity,
                        MinAirflow = caseFanDto.MinAirflow,
                        MaxAirflow = caseFanDto.MaxAirflow,
                        MinNoiseLevel = caseFanDto.MinNoiseLevel,
                        MaxNoiseLevel = caseFanDto.MaxNoiseLevel,
                        PulseWidthModulation = caseFanDto.PulseWidthModulation,
                        LEDType = caseFanDto.LEDType,
                        ConnectorType = caseFanDto.ConnectorType,
                        ControllerType = caseFanDto.ControllerType,
                        StaticPressureAmount = caseFanDto.StaticPressureAmount,
                        FlowDirection = caseFanDto.FlowDirection,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateCoolerComponentDto coolerDto => new CoolerComponent
                    {
                        Name = coolerDto.Name,
                        Manufacturer = coolerDto.Manufacturer,
                        Release = coolerDto.Release,
                        Type = coolerDto.Type,
                        MinFanRotationSpeed = coolerDto.MinFanRotationSpeed,
                        MaxFanRotationSpeed = coolerDto.MaxFanRotationSpeed,
                        MinNoiseLevel = coolerDto.MinNoiseLevel,
                        MaxNoiseLevel = coolerDto.MaxNoiseLevel,
                        Height = coolerDto.Height,
                        IsWaterCooled = coolerDto.IsWaterCooled,
                        RadiatorSize = coolerDto.RadiatorSize,
                        CanOperateFanless = coolerDto.CanOperateFanless,
                        FanSize = coolerDto.FanSize,
                        FanQuantity = coolerDto.FanQuantity,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateCPUComponentDto cpuDto => new CPUComponent
                    {
                        Name = cpuDto.Name,
                        Manufacturer = cpuDto.Manufacturer,
                        Release = cpuDto.Release,
                        Type = cpuDto.Type,
                        Series = cpuDto.Series,
                        Microarchitecture = cpuDto.Microarchitecture,
                        CoreFamily = cpuDto.CoreFamily,
                        SocketType = cpuDto.SocketType,
                        CoreTotal = cpuDto.CoreTotal,
                        PerformanceAmount = cpuDto.PerformanceAmount,
                        EfficiencyAmount = cpuDto.EfficiencyAmount,
                        ThreadsAmount = cpuDto.ThreadsAmount,
                        BasePerformanceSpeed = cpuDto.BasePerformanceSpeed,
                        BoostPerformanceSpeed = cpuDto.BoostPerformanceSpeed,
                        BaseEfficiencySpeed = cpuDto.BaseEfficiencySpeed,
                        BoostEfficiencySpeed = cpuDto.BoostEfficiencySpeed,
                        L1 = cpuDto.L1,
                        L2 = cpuDto.L2,
                        L3 = cpuDto.L3,
                        L4 = cpuDto.L4,
                        IncludesCooler = cpuDto.IncludesCooler,
                        Lithography = cpuDto.Lithography,
                        SupportsSimultaneousMultithreading = cpuDto.SupportsSimultaneousMultithreading,
                        MemoryType = cpuDto.MemoryType,
                        PackagingType = cpuDto.PackagingType,
                        SupportsErrorCorrectingCode = cpuDto.SupportsErrorCorrectingCode,
                        ThermalDesignPower = cpuDto.ThermalDesignPower,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateGPUComponentDto gpuDto => new GPUComponent
                    {
                        Name = gpuDto.Name,
                        Manufacturer = gpuDto.Manufacturer,
                        Release = gpuDto.Release,
                        Type = gpuDto.Type,
                        Chipset = gpuDto.Chipset,
                        VideoMemoryAmount = gpuDto.VideoMemoryAmount,
                        VideoMemoryType = gpuDto.VideoMemoryType,
                        CoreBaseClockSpeed = gpuDto.CoreBaseClockSpeed,
                        CoreBoostClockSpeed = gpuDto.CoreBoostClockSpeed,
                        CoreCount = gpuDto.CoreCount,
                        EffectiveMemoryClockSpeed = gpuDto.EffectiveMemoryClockSpeed,
                        MemoryBusWidth = gpuDto.MemoryBusWidth,
                        FrameSync = gpuDto.FrameSync,
                        Length = gpuDto.Length,
                        ThermalDesignPower = gpuDto.ThermalDesignPower,
                        CaseExpansionSlotWidth = gpuDto.CaseExpansionSlotWidth,
                        TotalSlotWidth = gpuDto.TotalSlotWidth,
                        CoolingType = gpuDto.CoolingType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateMemoryComponentDto memoryDto => new MemoryComponent
                    {
                        Name = memoryDto.Name,
                        Manufacturer = memoryDto.Manufacturer,
                        Release = memoryDto.Release,
                        Type = memoryDto.Type,
                        Speed = memoryDto.Speed,
                        RAMType = memoryDto.RAMType,
                        FormFactor = memoryDto.FormFactor,
                        Capacity = memoryDto.Capacity,
                        CASLatency = memoryDto.CASLatency,
                        Timings = memoryDto.Timings,
                        ModuleQuantity = memoryDto.ModuleQuantity,
                        ModuleCapacity = memoryDto.ModuleCapacity,
                        ErrorCorrectingCode = memoryDto.ErrorCorrectingCode,
                        RegisteredType = memoryDto.RegisteredType,
                        HaveHeatSpreader = memoryDto.HaveHeatSpreader,
                        HaveRGB = memoryDto.HaveRGB,
                        Height = memoryDto.Height,
                        Voltage = memoryDto.Voltage,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateMonitorComponentDto monitorDto => new MonitorComponent
                    {
                        Name = monitorDto.Name,
                        Manufacturer = monitorDto.Manufacturer,
                        Release = monitorDto.Release,
                        Type = monitorDto.Type,
                        ScreenSize = monitorDto.ScreenSize,
                        HorizontalResolution = monitorDto.HorizontalResolution,
                        VerticalResolution = monitorDto.VerticalResolution,
                        MaxRefreshRate = monitorDto.MaxRefreshRate,
                        PanelType = monitorDto.PanelType,
                        ResponseTime = monitorDto.ResponseTime,
                        ViewingAngle = monitorDto.ViewingAngle,
                        AspectRatio = monitorDto.AspectRatio,
                        MaxBrightness = monitorDto.MaxBrightness,
                        HighDynamicRangeType = monitorDto.HighDynamicRangeType,
                        AdaptiveSyncType = monitorDto.AdaptiveSyncType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateMotherboardComponentDto motherboardDto => new MotherboardComponent
                    {
                        Name = motherboardDto.Name,
                        Manufacturer = motherboardDto.Manufacturer,
                        Release = motherboardDto.Release,
                        Type = motherboardDto.Type,
                        SocketType = motherboardDto.SocketType,
                        FormFactor = motherboardDto.FormFactor,
                        ChipsetType = motherboardDto.ChipsetType,
                        RAMType = motherboardDto.RAMType,
                        RAMSlotsAmount = motherboardDto.RAMSlotsAmount,
                        MaxRAMAmount = motherboardDto.MaxRAMAmount,
                        SerialATAttachment6GBsAmount = motherboardDto.SerialATAttachment6GBsAmount,
                        SerialATAttachment3GBsAmount = motherboardDto.SerialATAttachment3GBsAmount,
                        U2PortAmount = motherboardDto.U2PortAmount,
                        WirelessNetworkingStandard = motherboardDto.WirelessNetworkingStandard,
                        CPUFanHeaderAmount = motherboardDto.CPUFanHeaderAmount,
                        CaseFanHeaderAmount = motherboardDto.CaseFanHeaderAmount,
                        PumpHeaderAmount = motherboardDto.PumpHeaderAmount,
                        CPUOptionalFanHeaderAmount = motherboardDto.CPUOptionalFanHeaderAmount,
                        ARGB5vHeaderAmount = motherboardDto.ARGB5vHeaderAmount,
                        RGB12vHeaderAmount = motherboardDto.RGB12vHeaderAmount,
                        HasPowerButtonHeader = motherboardDto.HasPowerButtonHeader,
                        HasResetButtonHeader = motherboardDto.HasResetButtonHeader,
                        HasPowerLEDHeader = motherboardDto.HasPowerLEDHeader,
                        HasHDDLEDHeader = motherboardDto.HasHDDLEDHeader,
                        TemperatureSensorHeaderAmount = motherboardDto.TemperatureSensorHeaderAmount,
                        ThunderboltHeaderAmount = motherboardDto.ThunderboltHeaderAmount,
                        COMPortHeaderAmount = motherboardDto.COMPortHeaderAmount,
                        MainPowerType = motherboardDto.MainPowerType,
                        HasECCSupport = motherboardDto.HasECCSupport,
                        HasRAIDSupport = motherboardDto.HasRAIDSupport,
                        HasFlashback = motherboardDto.HasFlashback,
                        HasCMOS = motherboardDto.HasCMOS,
                        AudioChipset = motherboardDto.AudioChipset,
                        MaxAudioChannels = motherboardDto.MaxAudioChannels,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreatePowerSupplyComponentDto powerSupplyDto => new PowerSupplyComponent
                    {
                        Name = powerSupplyDto.Name,
                        Manufacturer = powerSupplyDto.Manufacturer,
                        Release = powerSupplyDto.Release,
                        Type = powerSupplyDto.Type,
                        PowerOutput = powerSupplyDto.PowerOutput,
                        FormFactor = powerSupplyDto.FormFactor,
                        EfficiencyRating = powerSupplyDto.EfficiencyRating,
                        ModularityType = powerSupplyDto.ModularityType,
                        Length = powerSupplyDto.Length,
                        IsFanless = powerSupplyDto.IsFanless,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateStorageComponentDto storageDto => new StorageComponent
                    {
                        Name = storageDto.Name,
                        Manufacturer = storageDto.Manufacturer,
                        Release = storageDto.Release,
                        Type = storageDto.Type,
                        Series = storageDto.Series,
                        Capacity = storageDto.Capacity,
                        DriveType = storageDto.DriveType,
                        FormFactor = storageDto.FormFactor,
                        Interface = storageDto.Interface,
                        HasNVMe = storageDto.HasNVMe,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    _ => throw new NotImplementedException("Invalid Component Type"),
                };
            }
            catch (Exception ex)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Component",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"Operation Failed - {ex}"
                );

                //Return not found response
                return BadRequest(new { component = "Component not found!" });
            }

            //Add the component to the database
            _db.Components.Add(component);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Component",
                ip,
                component.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Component Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("component.created", new
            {
                componentId = component.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { component = "Component sent successfully!", id = component.Id });
        }

        //API endpoint for updating the selected Component
        //User can modify only their own Components,
        //while admins can modify all 
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponent(Guid id, [FromBody] UpdateBaseComponentDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the component to edit
            var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the component exists
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Component",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Component"
                );

                //Return not found response
                return NotFound(new { component = "Component not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update fields based on the component type
            switch(dto)
            {
                case UpdateCaseComponentDto caseDto:
                {
                    if (!string.IsNullOrWhiteSpace(caseDto.FormFactor))
                    {
                        changedFields.Add("FormFactor: " + ((CaseComponent)component).FormFactor);

                        ((CaseComponent)component).FormFactor = caseDto.FormFactor;
                    }
                    if (caseDto.PowerSupplyShrouded != null)
                    {
                        changedFields.Add("PowerSupplyShrouded: " + ((CaseComponent)component).PowerSupplyShrouded);

                        ((CaseComponent)component).PowerSupplyShrouded = (bool)caseDto.PowerSupplyShrouded;
                    }
                    if (caseDto.PowerSupplyAmount != null)
                    {
                        changedFields.Add("PowerSupplyAmount: " + ((CaseComponent)component).PowerSupplyAmount);

                        if (caseDto.PowerSupplyAmount == 0)
                            ((CaseComponent)component).PowerSupplyAmount = null;
                        else
                            ((CaseComponent)component).PowerSupplyAmount = caseDto.PowerSupplyAmount;
                    }
                    if (caseDto.HasTransparentSidePanel != null)
                    {
                        changedFields.Add("HasTransparentSidePanel: " + ((CaseComponent)component).HasTransparentSidePanel);

                        ((CaseComponent)component).HasTransparentSidePanel = (bool)caseDto.HasTransparentSidePanel;
                    }
                    if (caseDto.SidePanelType != null)
                    {
                        changedFields.Add("SidePanelType: " + ((CaseComponent)component).SidePanelType);

                        if (string.IsNullOrWhiteSpace(caseDto.SidePanelType))
                            ((CaseComponent)component).SidePanelType = null;
                        else
                            ((CaseComponent)component).SidePanelType = caseDto.SidePanelType;
                    }
                    if (caseDto.MaxVideoCardLength != null)
                    {
                        changedFields.Add("MaxVideoCardLength: " + ((CaseComponent)component).MaxVideoCardLength);

                        ((CaseComponent)component).MaxVideoCardLength = (decimal)caseDto.MaxVideoCardLength;
                    }
                    if (caseDto.MaxCPUCoolerHeight != null)
                    {
                        changedFields.Add("MaxCPUCoolerHeight: " + ((CaseComponent)component).MaxCPUCoolerHeight);

                        ((CaseComponent)component).MaxCPUCoolerHeight = (decimal)caseDto.MaxCPUCoolerHeight;
                    }
                    if (caseDto.Internal35BayAmount != null)
                    {
                        changedFields.Add("Internal35BayAmount: " + ((CaseComponent)component).Internal35BayAmount);

                        ((CaseComponent)component).Internal35BayAmount = (int)caseDto.Internal35BayAmount;
                    }
                    if (caseDto.Internal25BayAmount != null)
                    {
                        changedFields.Add("Internal25BayAmount: " + ((CaseComponent)component).Internal25BayAmount);

                        ((CaseComponent)component).Internal25BayAmount = (int)caseDto.Internal25BayAmount;
                    }
                    if (caseDto.External35BayAmount != null)
                    {
                        changedFields.Add("External35BayAmount: " + ((CaseComponent)component).External35BayAmount);

                        ((CaseComponent)component).External35BayAmount = (int)caseDto.External35BayAmount;
                    }
                    if (caseDto.External525BayAmount != null)
                    {
                        changedFields.Add("External525BayAmount: " + ((CaseComponent)component).External525BayAmount);

                        ((CaseComponent)component).External525BayAmount = (int)caseDto.External525BayAmount;
                    }
                    if (caseDto.ExpansionSlotAmount != null)
                    {
                        changedFields.Add("ExpansionSlotAmount: " + ((CaseComponent)component).ExpansionSlotAmount);

                        ((CaseComponent)component).ExpansionSlotAmount = (int)caseDto.ExpansionSlotAmount;
                    }
                    if (caseDto.Width != null)
                    {
                        changedFields.Add("Width: " + ((CaseComponent)component).Dimensions.Width);

                        ((CaseComponent)component).Dimensions.Width = (decimal)caseDto.Width;
                    }
                    if (caseDto.Height != null)
                    {
                        changedFields.Add("Height: " + ((CaseComponent)component).Dimensions.Height);

                        ((CaseComponent)component).Dimensions.Height = (decimal)caseDto.Height;
                    }
                    if (caseDto.Depth != null)
                    {
                        changedFields.Add("Depth: " + ((CaseComponent)component).Dimensions.Depth);

                        ((CaseComponent)component).Dimensions.Depth = (decimal)caseDto.Depth;
                    }
                    if (caseDto.Weight != null)
                    {
                        changedFields.Add("Weight: " + ((CaseComponent)component).Weight);

                        ((CaseComponent)component).Weight = (decimal)caseDto.Weight;
                    }
                    if (caseDto.SupportsRearConnectingMotherboard != null)
                    {
                        changedFields.Add("SupportsRearConnectingMotherboard: " + ((CaseComponent)component).SupportsRearConnectingMotherboard);

                        ((CaseComponent)component).SupportsRearConnectingMotherboard = (bool)caseDto.SupportsRearConnectingMotherboard;
                    }
                    break;
                }
                case UpdateCaseFanComponentDto caseFanDto:
                {
                    if (caseFanDto.Size != null)
                    {
                        changedFields.Add("Weight: " + ((CaseFanComponent)component).Size);

                        ((CaseFanComponent)component).Size = (decimal)caseFanDto.Size;
                    }
                    if (caseFanDto.Quantity != null)
                    {
                        changedFields.Add("Quantity: " + ((CaseFanComponent)component).Quantity);

                        ((CaseFanComponent)component).Quantity = (int)caseFanDto.Quantity;
                    }
                    if (caseFanDto.MinAirflow != null)
                    {
                        changedFields.Add("MinAirflow: " + ((CaseFanComponent)component).MinAirflow);

                        ((CaseFanComponent)component).MinAirflow = (decimal)caseFanDto.MinAirflow;
                    }
                    if (caseFanDto.MaxAirflow != null)
                    {
                        changedFields.Add("MaxAirflow: " + ((CaseFanComponent)component).MaxAirflow);

                        if (caseFanDto.MaxAirflow == 0)
                            ((CaseFanComponent)component).MaxAirflow = null;
                        else
                            ((CaseFanComponent)component).MaxAirflow = (decimal)caseFanDto.MaxAirflow;
                    }
                    if (caseFanDto.MinNoiseLevel != null)
                    {
                        changedFields.Add("MinNoiseLevel: " + ((CaseFanComponent)component).MinNoiseLevel);

                        ((CaseFanComponent)component).MinNoiseLevel = (decimal)caseFanDto.MinNoiseLevel;
                    }
                    if (caseFanDto.MaxNoiseLevel != null)
                    {
                        changedFields.Add("MaxNoiseLevel: " + ((CaseFanComponent)component).MaxNoiseLevel);

                        if (caseFanDto.MaxNoiseLevel == 0)
                            ((CaseFanComponent)component).MaxNoiseLevel = null;
                        else
                            ((CaseFanComponent)component).MaxNoiseLevel = caseFanDto.MaxNoiseLevel;
                    }
                    if (caseFanDto.PulseWidthModulation != null)
                    {
                        changedFields.Add("PulseWidthModulation: " + ((CaseFanComponent)component).PulseWidthModulation);

                        ((CaseFanComponent)component).PulseWidthModulation = (bool)caseFanDto.PulseWidthModulation;
                    }
                    if (caseFanDto.LEDType != null)
                    {
                        changedFields.Add("LEDType: " + ((CaseFanComponent)component).LEDType);

                        if (string.IsNullOrWhiteSpace(caseFanDto.LEDType))
                            ((CaseFanComponent)component).LEDType = null;
                        else
                            ((CaseFanComponent)component).LEDType = caseFanDto.LEDType;
                    }
                    if (caseFanDto.ConnectorType != null)
                    {
                        changedFields.Add("ConnectorType: " + ((CaseFanComponent)component).ConnectorType);

                        if (string.IsNullOrWhiteSpace(caseFanDto.ConnectorType))
                            ((CaseFanComponent)component).ConnectorType = null;
                        else
                            ((CaseFanComponent)component).ConnectorType = caseFanDto.ConnectorType;
                    }
                    if (caseFanDto.ControllerType != null)
                    {
                        changedFields.Add("ControllerType: " + ((CaseFanComponent)component).ControllerType);

                        if (string.IsNullOrWhiteSpace(caseFanDto.ControllerType))
                            ((CaseFanComponent)component).ControllerType = null;
                        else
                            ((CaseFanComponent)component).ControllerType = caseFanDto.ControllerType;
                    }
                    if (caseFanDto.StaticPressureAmount != null)
                    {
                        changedFields.Add("StaticPressureAmount: " + ((CaseFanComponent)component).StaticPressureAmount);

                        ((CaseFanComponent)component).StaticPressureAmount = (decimal)caseFanDto.StaticPressureAmount;
                    }
                    if (!string.IsNullOrWhiteSpace(caseFanDto.FlowDirection))
                    {
                        changedFields.Add("FlowDirection: " + ((CaseFanComponent)component).FlowDirection);

                        ((CaseFanComponent)component).FlowDirection = caseFanDto.FlowDirection;
                    }
                    break;
                }
                case UpdateCoolerComponentDto coolerDto:
                {
                    if (coolerDto.MinFanRotationSpeed != null)
                    {
                        changedFields.Add("MinFanRotationSpeed: " + ((CoolerComponent)component).MinFanRotationSpeed);

                        if (coolerDto.MaxNoiseLevel == 0)
                            ((CoolerComponent)component).MinFanRotationSpeed = null;
                        else
                            ((CoolerComponent)component).MinFanRotationSpeed = coolerDto.MinFanRotationSpeed;
                    }
                    if (coolerDto.MaxFanRotationSpeed != null)
                    {
                        changedFields.Add("MaxFanRotationSpeed: " + ((CoolerComponent)component).MaxFanRotationSpeed);

                        if (coolerDto.MaxNoiseLevel == 0)
                            ((CoolerComponent)component).MaxFanRotationSpeed = null;
                        else
                            ((CoolerComponent)component).MaxFanRotationSpeed = coolerDto.MaxFanRotationSpeed;
                    }
                    if (coolerDto.MinNoiseLevel != null)
                    {
                        changedFields.Add("MinNoiseLevel: " + ((CoolerComponent)component).MinNoiseLevel);

                        if (coolerDto.MaxNoiseLevel == 0)
                            ((CoolerComponent)component).MinNoiseLevel = null;
                        else
                            ((CoolerComponent)component).MinNoiseLevel = coolerDto.MinNoiseLevel;
                    }
                    if (coolerDto.MaxNoiseLevel != null)
                    {
                        changedFields.Add("MaxNoiseLevel: " + ((CoolerComponent)component).MaxNoiseLevel);

                        if (coolerDto.MaxNoiseLevel == 0)
                            ((CoolerComponent)component).MaxNoiseLevel = null;
                        else
                            ((CoolerComponent)component).MaxNoiseLevel = coolerDto.MaxNoiseLevel;
                    }
                    if (coolerDto.Height != null)
                    {
                        changedFields.Add("Height: " + ((CoolerComponent)component).Height);

                        ((CoolerComponent)component).Height = (decimal)coolerDto.Height;
                    }
                    if (coolerDto.IsWaterCooled != null)
                    {
                        changedFields.Add("IsWaterCooled: " + ((CoolerComponent)component).IsWaterCooled);

                        ((CoolerComponent)component).IsWaterCooled = (bool)coolerDto.IsWaterCooled;
                    }
                    if (coolerDto.RadiatorSize != null)
                    {
                        changedFields.Add("RadiatorSize: " + ((CoolerComponent)component).RadiatorSize);

                        if (coolerDto.RadiatorSize == 0)
                            ((CoolerComponent)component).RadiatorSize = null;
                        else
                            ((CoolerComponent)component).RadiatorSize = coolerDto.RadiatorSize;
                    }
                    if (coolerDto.CanOperateFanless != null)
                    {
                        changedFields.Add("CanOperateFanless: " + ((CoolerComponent)component).CanOperateFanless);

                        ((CoolerComponent)component).CanOperateFanless = (bool)coolerDto.CanOperateFanless;
                    }
                    if (coolerDto.FanSize != null)
                    {
                        changedFields.Add("FanSize: " + ((CoolerComponent)component).FanSize);

                        if (coolerDto.FanSize == 0)
                            ((CoolerComponent)component).FanSize = null;
                        else
                            ((CoolerComponent)component).FanSize = (decimal)coolerDto.FanSize;
                    }
                    if (coolerDto.FanQuantity != null)
                    {
                        changedFields.Add("FanQuantity: " + ((CoolerComponent)component).FanQuantity);

                        if (coolerDto.FanQuantity == 0)
                            ((CoolerComponent)component).FanQuantity = null;
                        else
                            ((CoolerComponent)component).FanQuantity = (int)coolerDto.FanQuantity;
                    }
                    break;
                }
                case UpdateCPUComponentDto cpuDto:
                {
                    if (!string.IsNullOrWhiteSpace(cpuDto.Series))
                    {
                        changedFields.Add("Series: " + ((CPUComponent)component).Series);

                        ((CPUComponent)component).Series = cpuDto.Series;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.Microarchitecture))
                    {
                        changedFields.Add("Microarchitecture: " + ((CPUComponent)component).Microarchitecture);

                        ((CPUComponent)component).Microarchitecture = cpuDto.Microarchitecture;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.CoreFamily))
                    {
                        changedFields.Add("CoreFamily: " + ((CPUComponent)component).CoreFamily);

                        ((CPUComponent)component).CoreFamily = cpuDto.CoreFamily;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.SocketType))
                    {
                        changedFields.Add("SocketType: " + ((CPUComponent)component).SocketType);

                        ((CPUComponent)component).SocketType = cpuDto.SocketType;
                    }
                    if (cpuDto.CoreTotal != null)
                    {
                        changedFields.Add("CoreTotal: " + ((CPUComponent)component).CoreTotal);

                        ((CPUComponent)component).CoreTotal = (int)cpuDto.CoreTotal;
                    }
                    if (cpuDto.PerformanceAmount != null)
                    {
                        changedFields.Add("PerformanceAmount: " + ((CPUComponent)component).PerformanceAmount);

                        if (cpuDto.PerformanceAmount == 0)
                            ((CPUComponent)component).PerformanceAmount = null;
                        else
                            ((CPUComponent)component).PerformanceAmount = cpuDto.PerformanceAmount;
                    }
                    if (cpuDto.EfficiencyAmount != null)
                    {
                        changedFields.Add("EfficiencyAmount: " + ((CPUComponent)component).EfficiencyAmount);

                        if (cpuDto.PerformanceAmount == 0)
                            ((CPUComponent)component).EfficiencyAmount = null;
                        else
                            ((CPUComponent)component).EfficiencyAmount = cpuDto.EfficiencyAmount;
                    }
                    if (cpuDto.ThreadsAmount != null)
                    {
                        changedFields.Add("ThreadsAmount: " + ((CPUComponent)component).ThreadsAmount);

                        ((CPUComponent)component).ThreadsAmount = (int)cpuDto.ThreadsAmount;
                    }
                    if (cpuDto.BasePerformanceSpeed != null)
                    {
                        changedFields.Add("BasePerformanceSpeed: " + ((CPUComponent)component).BasePerformanceSpeed);

                        if (cpuDto.BasePerformanceSpeed == 0)
                            ((CPUComponent)component).BasePerformanceSpeed = null;
                        else
                            ((CPUComponent)component).BasePerformanceSpeed = cpuDto.BasePerformanceSpeed;
                    }
                    if (cpuDto.BoostPerformanceSpeed != null)
                    {
                        changedFields.Add("BoostPerformanceSpeed: " + ((CPUComponent)component).BoostPerformanceSpeed);

                        if (cpuDto.BoostPerformanceSpeed == 0)
                            ((CPUComponent)component).BoostPerformanceSpeed = null;
                        else
                            ((CPUComponent)component).BoostPerformanceSpeed = cpuDto.BoostPerformanceSpeed;
                    }
                    if (cpuDto.BaseEfficiencySpeed != null)
                    {
                        changedFields.Add("BaseEfficiencySpeed: " + ((CPUComponent)component).BaseEfficiencySpeed);

                        if (cpuDto.BaseEfficiencySpeed == 0)
                            ((CPUComponent)component).BaseEfficiencySpeed = null;
                        else
                            ((CPUComponent)component).BaseEfficiencySpeed = cpuDto.BaseEfficiencySpeed;
                    }
                    if (cpuDto.BoostEfficiencySpeed != null)
                    {
                        changedFields.Add("BoostEfficiencySpeed: " + ((CPUComponent)component).BoostEfficiencySpeed);

                        if (cpuDto.BoostEfficiencySpeed == 0)
                            ((CPUComponent)component).BoostEfficiencySpeed = null;
                        else
                            ((CPUComponent)component).BoostEfficiencySpeed = cpuDto.BoostEfficiencySpeed;
                    }
                    if (cpuDto.L1 != null)
                    {
                        changedFields.Add("L1: " + ((CPUComponent)component).L1);

                        if (cpuDto.L1 == 0)
                            ((CPUComponent)component).L1 = null;
                        else
                            ((CPUComponent)component).L1 = cpuDto.L1;
                    }
                    if (cpuDto.L2 != null)
                    {
                        changedFields.Add("L2: " + ((CPUComponent)component).L2);

                        if (cpuDto.L2 == 0)
                            ((CPUComponent)component).L2 = null;
                        else
                            ((CPUComponent)component).L2 = cpuDto.L2;
                    }
                    if (cpuDto.L3 != null)
                    {
                        changedFields.Add("L3: " + ((CPUComponent)component).L3);

                        if (cpuDto.L3 == 0)
                            ((CPUComponent)component).L3 = null;
                        else
                            ((CPUComponent)component).L3 = cpuDto.L3;
                    }
                    if (cpuDto.L4 != null)
                    {
                        changedFields.Add("L4: " + ((CPUComponent)component).L4);

                        if (cpuDto.L4 == 0)
                            ((CPUComponent)component).L4 = null;
                        else
                            ((CPUComponent)component).L4 = cpuDto.L4;
                    }
                    if (cpuDto.IncludesCooler != null)
                    {
                        changedFields.Add("IncludesCooler: " + ((CPUComponent)component).IncludesCooler);

                        ((CPUComponent)component).IncludesCooler = (bool)cpuDto.IncludesCooler;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.Lithography))
                    {
                        changedFields.Add("Lithography: " + ((CPUComponent)component).Lithography);

                        ((CPUComponent)component).Lithography = cpuDto.Lithography;
                    }
                    if (cpuDto.SupportsSimultaneousMultithreading != null)
                    {
                        changedFields.Add("SupportsSimultaneousMultithreading: " + ((CPUComponent)component).SupportsSimultaneousMultithreading);

                        ((CPUComponent)component).SupportsSimultaneousMultithreading = (bool)cpuDto.SupportsSimultaneousMultithreading;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.MemoryType))
                    {
                        changedFields.Add("MemoryType: " + ((CPUComponent)component).MemoryType);

                        ((CPUComponent)component).MemoryType = cpuDto.MemoryType;
                    }
                    if (!string.IsNullOrWhiteSpace(cpuDto.PackagingType))
                    {
                        changedFields.Add("PackagingType: " + ((CPUComponent)component).PackagingType);

                        ((CPUComponent)component).PackagingType = cpuDto.PackagingType;
                    }
                    if (cpuDto.SupportsErrorCorrectingCode != null)
                    {
                        changedFields.Add("SupportsErrorCorrectingCode: " + ((CPUComponent)component).SupportsErrorCorrectingCode);

                        ((CPUComponent)component).SupportsErrorCorrectingCode = (bool)cpuDto.SupportsErrorCorrectingCode;
                    }
                    if (cpuDto.ThermalDesignPower != null)
                    {
                        changedFields.Add("ThermalDesignPower: " + ((CPUComponent)component).ThermalDesignPower);

                        ((CPUComponent)component).ThermalDesignPower = (decimal)cpuDto.ThermalDesignPower;
                    }
                    break;
                }
                case UpdateGPUComponentDto gpuDto:
                {
                    if (!string.IsNullOrWhiteSpace(gpuDto.Chipset))
                    {
                        changedFields.Add("Chipset: " + ((GPUComponent)component).Chipset);

                        ((GPUComponent)component).Chipset = gpuDto.Chipset;
                    }
                    if (gpuDto.VideoMemoryAmount != null)
                    {
                        changedFields.Add("VideoMemoryAmount: " + ((GPUComponent)component).VideoMemoryAmount);

                        ((GPUComponent)component).VideoMemoryAmount = (decimal)gpuDto.VideoMemoryAmount;
                    }
                    if (!string.IsNullOrWhiteSpace(gpuDto.VideoMemoryType))
                    {
                        changedFields.Add("VideoMemoryType: " + ((GPUComponent)component).VideoMemoryType);

                        ((GPUComponent)component).VideoMemoryType = gpuDto.VideoMemoryType;
                    }
                    if (gpuDto.CoreBaseClockSpeed != null)
                    {
                        changedFields.Add("CoreBaseClockSpeed: " + ((GPUComponent)component).CoreBaseClockSpeed);

                        ((GPUComponent)component).CoreBaseClockSpeed = (decimal)gpuDto.CoreBaseClockSpeed;
                    }
                    if (gpuDto.CoreBoostClockSpeed != null)
                    {
                        changedFields.Add("CoreBoostClockSpeed: " + ((GPUComponent)component).CoreBoostClockSpeed);

                        ((GPUComponent)component).CoreBoostClockSpeed = (decimal)gpuDto.CoreBoostClockSpeed;
                    }
                    if (gpuDto.CoreCount != null)
                    {
                        changedFields.Add("CoreCount: " + ((GPUComponent)component).CoreCount);

                        ((GPUComponent)component).CoreCount = (int)gpuDto.CoreCount;
                    }
                    if (gpuDto.EffectiveMemoryClockSpeed != null)
                    {
                        changedFields.Add("EffectiveMemoryClockSpeed: " + ((GPUComponent)component).EffectiveMemoryClockSpeed);

                        ((GPUComponent)component).EffectiveMemoryClockSpeed = (decimal)gpuDto.EffectiveMemoryClockSpeed;
                    }
                    if (gpuDto.MemoryBusWidth != null)
                    {
                        changedFields.Add("MemoryBusWidth: " + ((GPUComponent)component).MemoryBusWidth);

                        ((GPUComponent)component).MemoryBusWidth = (int)gpuDto.MemoryBusWidth;
                    }
                    if (!string.IsNullOrWhiteSpace(gpuDto.FrameSync))
                    {
                        changedFields.Add("FrameSync: " + ((GPUComponent)component).FrameSync);

                        ((GPUComponent)component).FrameSync = gpuDto.FrameSync;
                    }
                    if (gpuDto.Length != null)
                    {
                        changedFields.Add("Length: " + ((GPUComponent)component).Length);

                        ((GPUComponent)component).Length = (decimal)gpuDto.Length;
                    }
                    if (gpuDto.ThermalDesignPower != null)
                    {
                        changedFields.Add("ThermalDesignPower: " + ((GPUComponent)component).ThermalDesignPower);

                        ((GPUComponent)component).ThermalDesignPower = (decimal)gpuDto.ThermalDesignPower;
                    }
                    if (gpuDto.CaseExpansionSlotWidth != null)
                    {
                        changedFields.Add("CaseExpansionSlotWidth: " + ((GPUComponent)component).CaseExpansionSlotWidth);

                        ((GPUComponent)component).CaseExpansionSlotWidth = (int)gpuDto.CaseExpansionSlotWidth;
                    }
                    if (gpuDto.TotalSlotWidth != null)
                    {
                        changedFields.Add("TotalSlotWidth: " + ((GPUComponent)component).TotalSlotWidth);

                        ((GPUComponent)component).TotalSlotWidth = (int)gpuDto.TotalSlotWidth;
                    }
                    if (!string.IsNullOrWhiteSpace(gpuDto.CoolingType))
                    {
                        changedFields.Add("CoolingType: " + ((GPUComponent)component).CoolingType);

                        ((GPUComponent)component).CoolingType = gpuDto.CoolingType;
                    }
                    break;
                }
                case UpdateMemoryComponentDto memoryDto:
                {
                    if (memoryDto.Speed != null)
                    {
                        changedFields.Add("Speed: " + ((MemoryComponent)component).Speed);

                        ((MemoryComponent)component).Speed = (decimal)memoryDto.Speed;
                    }
                    if (!string.IsNullOrWhiteSpace(memoryDto.RAMType))
                    {
                        changedFields.Add("RAMType: " + ((MemoryComponent)component).RAMType);

                        ((MemoryComponent)component).RAMType = memoryDto.RAMType;
                    }
                    if (!string.IsNullOrWhiteSpace(memoryDto.FormFactor))
                    {
                        changedFields.Add("FormFactor: " + ((MemoryComponent)component).FormFactor);

                        ((MemoryComponent)component).FormFactor = memoryDto.FormFactor;
                    }
                    if (memoryDto.Capacity != null)
                    {
                        changedFields.Add("Capacity: " + ((MemoryComponent)component).Capacity);

                        ((MemoryComponent)component).Capacity = (decimal)memoryDto.Capacity;
                    }
                    if (memoryDto.CASLatency != null)
                    {
                        changedFields.Add("CASLatency: " + ((MemoryComponent)component).CASLatency);

                        ((MemoryComponent)component).CASLatency = (decimal)memoryDto.CASLatency;
                    }
                    if (memoryDto.Timings != null)
                    {
                        changedFields.Add("Timings: " + ((MemoryComponent)component).Timings);

                        if (string.IsNullOrWhiteSpace(memoryDto.Timings))
                            ((MemoryComponent)component).Timings = null;
                        else
                            ((MemoryComponent)component).Timings = memoryDto.Timings;
                    }
                    if (memoryDto.ModuleQuantity != null)
                    {
                        changedFields.Add("ModuleQuantity: " + ((MemoryComponent)component).ModuleQuantity);

                        ((MemoryComponent)component).ModuleQuantity = (int)memoryDto.ModuleQuantity;
                    }
                    if (memoryDto.ModuleCapacity != null)
                    {
                        changedFields.Add("ModuleCapacity: " + ((MemoryComponent)component).ModuleCapacity);

                        ((MemoryComponent)component).ModuleCapacity = (int)memoryDto.ModuleCapacity;
                    }
                    if (!string.IsNullOrWhiteSpace(memoryDto.ErrorCorrectingCode))
                    {
                        changedFields.Add("FormFactor: " + ((MemoryComponent)component).ErrorCorrectingCode);

                        ((MemoryComponent)component).ErrorCorrectingCode = memoryDto.ErrorCorrectingCode;
                    }
                    if (!string.IsNullOrWhiteSpace(memoryDto.RegisteredType))
                    {
                        changedFields.Add("RegisteredType: " + ((MemoryComponent)component).RegisteredType);

                        ((MemoryComponent)component).RegisteredType = memoryDto.RegisteredType;
                    }
                    if (memoryDto.HaveHeatSpreader != null)
                    {
                        changedFields.Add("HaveHeatSpreader: " + ((MemoryComponent)component).HaveHeatSpreader);

                        ((MemoryComponent)component).HaveHeatSpreader = (bool)memoryDto.HaveHeatSpreader;
                    }
                    if (memoryDto.HaveRGB != null)
                    {
                        changedFields.Add("HaveRGB: " + ((MemoryComponent)component).HaveRGB);

                        ((MemoryComponent)component).HaveRGB = (bool)memoryDto.HaveRGB;
                    }
                    if (memoryDto.Height != null)
                    {
                        changedFields.Add("Height: " + ((MemoryComponent)component).Height);

                        if (memoryDto.Height != null)
                            ((MemoryComponent)component).Height = null;
                        else
                            ((MemoryComponent)component).Height = memoryDto.Height;
                    }
                    if (memoryDto.Voltage != null)
                    {
                        changedFields.Add("Voltage: " + ((MemoryComponent)component).Voltage);

                        if (memoryDto.Voltage != null)
                            ((MemoryComponent)component).Voltage = null;
                        else
                            ((MemoryComponent)component).Voltage = memoryDto.Voltage;
                    }
                    break;
                }
                case UpdateMonitorComponentDto monitorDto:
                {
                    if (monitorDto.ScreenSize != null)
                    {
                        changedFields.Add("ScreenSize: " + ((MonitorComponent)component).ScreenSize);

                        ((MonitorComponent)component).ScreenSize = (decimal)monitorDto.ScreenSize;
                    }
                    if (monitorDto.HorizontalResolution != null)
                    {
                        changedFields.Add("HorizontalResolution: " + ((MonitorComponent)component).HorizontalResolution);

                        ((MonitorComponent)component).HorizontalResolution = (int)monitorDto.HorizontalResolution;
                    }
                    if (monitorDto.VerticalResolution != null)
                    {
                        changedFields.Add("VerticalResolution: " + ((MonitorComponent)component).VerticalResolution);

                        ((MonitorComponent)component).VerticalResolution = (int)monitorDto.VerticalResolution;
                    }
                    if (monitorDto.MaxRefreshRate != null)
                    {
                        changedFields.Add("MaxRefreshRate: " + ((MonitorComponent)component).MaxRefreshRate);

                        ((MonitorComponent)component).MaxRefreshRate = (decimal)monitorDto.MaxRefreshRate;
                    }
                    if ((!string.IsNullOrWhiteSpace(monitorDto.PanelType)))
                    {
                        changedFields.Add("PanelType: " + ((MonitorComponent)component).PanelType);

                        ((MonitorComponent)component).PanelType = monitorDto.PanelType;
                    }
                    if (monitorDto.ResponseTime != null)
                    {
                        changedFields.Add("ResponseTime: " + ((MonitorComponent)component).ResponseTime);

                        ((MonitorComponent)component).ResponseTime = (decimal)monitorDto.ResponseTime;
                    }
                    if ((!string.IsNullOrWhiteSpace(monitorDto.ViewingAngle)))
                    {
                        changedFields.Add("ViewingAngle: " + ((MonitorComponent)component).ViewingAngle);

                        ((MonitorComponent)component).ViewingAngle = monitorDto.ViewingAngle;
                    }
                    if ((!string.IsNullOrWhiteSpace(monitorDto.AspectRatio)))
                    {
                        changedFields.Add("AspectRatio: " + ((MonitorComponent)component).AspectRatio);

                        ((MonitorComponent)component).AspectRatio = monitorDto.AspectRatio;
                    }
                    if (monitorDto.MaxBrightness != null)
                    {
                        changedFields.Add("MaxBrightness: " + ((MonitorComponent)component).MaxBrightness);

                        if (monitorDto.MaxBrightness == 0)
                            ((MonitorComponent)component).MaxBrightness = null;
                        else
                            ((MonitorComponent)component).MaxBrightness = monitorDto.MaxBrightness;
                    }
                    if (monitorDto.HighDynamicRangeType != null)
                    {
                        changedFields.Add("HighDynamicRangeType: " + ((MonitorComponent)component).HighDynamicRangeType);

                        if (string.IsNullOrWhiteSpace(monitorDto.HighDynamicRangeType))
                            ((MonitorComponent)component).HighDynamicRangeType = null;
                        else
                            ((MonitorComponent)component).HighDynamicRangeType = monitorDto.HighDynamicRangeType;
                    }
                    if ((!string.IsNullOrWhiteSpace(monitorDto.AdaptiveSyncType)))
                    {
                        changedFields.Add("AdaptiveSyncType: " + ((MonitorComponent)component).AdaptiveSyncType);

                        ((MonitorComponent)component).AdaptiveSyncType = monitorDto.AdaptiveSyncType;
                    }
                    break;
                }
                case UpdateMotherboardComponentDto motherboardDto:
                {
                    if (!string.IsNullOrWhiteSpace(motherboardDto.SocketType))
                    {
                        changedFields.Add("SocketType: " + ((MotherboardComponent)component).SocketType);

                        ((MotherboardComponent)component).SocketType = motherboardDto.SocketType;
                    }
                    if (!string.IsNullOrWhiteSpace(motherboardDto.FormFactor))
                    {
                        changedFields.Add("FormFactor: " + ((MotherboardComponent)component).FormFactor);

                        ((MotherboardComponent)component).FormFactor = motherboardDto.FormFactor;
                    }
                    if (!string.IsNullOrWhiteSpace(motherboardDto.ChipsetType))
                    {
                        changedFields.Add("ChipsetType: " + ((MotherboardComponent)component).ChipsetType);

                        ((MotherboardComponent)component).ChipsetType = motherboardDto.ChipsetType;
                    }
                    if (!string.IsNullOrWhiteSpace(motherboardDto.RAMType))
                    {
                        changedFields.Add("RAMType: " + ((MotherboardComponent)component).RAMType);

                        ((MotherboardComponent)component).RAMType = motherboardDto.RAMType;
                    }
                    if (motherboardDto.MaxRAMAmount != null)
                    {
                        changedFields.Add("MaxRAMAmount: " + ((MotherboardComponent)component).MaxRAMAmount);

                        ((MotherboardComponent)component).MaxRAMAmount = (int)motherboardDto.MaxRAMAmount;
                    }
                    if (motherboardDto.RAMSlotsAmount != null)
                    {
                        changedFields.Add("RAMSlotsAmount: " + ((MotherboardComponent)component).RAMSlotsAmount);

                        ((MotherboardComponent)component).RAMSlotsAmount = (int)motherboardDto.RAMSlotsAmount;
                    }
                    if (motherboardDto.SerialATAttachment6GBsAmount != null)
                    {
                        changedFields.Add("SerialATAttachment6GBsAmount: " + ((MotherboardComponent)component).SerialATAttachment6GBsAmount);

                        ((MotherboardComponent)component).SerialATAttachment6GBsAmount = (int)motherboardDto.SerialATAttachment6GBsAmount;
                    }
                    if (motherboardDto.SerialATAttachment3GBsAmount != null)
                    {
                        changedFields.Add("MaxRAMAmount: " + ((MotherboardComponent)component).SerialATAttachment3GBsAmount);

                        ((MotherboardComponent)component).SerialATAttachment3GBsAmount = (int)motherboardDto.SerialATAttachment3GBsAmount;
                    }
                    if (motherboardDto.U2PortAmount != null)
                    {
                        changedFields.Add("U2PortAmount: " + ((MotherboardComponent)component).U2PortAmount);

                        ((MotherboardComponent)component).U2PortAmount = (int)motherboardDto.U2PortAmount;
                    }
                    if (motherboardDto.WirelessNetworkingStandard != null)
                    {
                        changedFields.Add("WirelessNetworkingStandard: " + ((MotherboardComponent)component).WirelessNetworkingStandard);

                        ((MotherboardComponent)component).WirelessNetworkingStandard = motherboardDto.WirelessNetworkingStandard;
                    }
                    if (motherboardDto.CPUFanHeaderAmount != null)
                    {
                        changedFields.Add("CPUFanHeaderAmount: " + ((MotherboardComponent)component).CPUFanHeaderAmount);

                        if (motherboardDto.CPUFanHeaderAmount == 0)
                            ((MotherboardComponent)component).CPUFanHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).CPUFanHeaderAmount = motherboardDto.CPUFanHeaderAmount;
                    }
                    if (motherboardDto.CaseFanHeaderAmount != null)
                    {
                        changedFields.Add("CaseFanHeaderAmount: " + ((MotherboardComponent)component).CaseFanHeaderAmount);

                        if (motherboardDto.CaseFanHeaderAmount == 0)
                            ((MotherboardComponent)component).CaseFanHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).CaseFanHeaderAmount = motherboardDto.CaseFanHeaderAmount;
                    }
                    if (motherboardDto.PumpHeaderAmount != null)
                    {
                        changedFields.Add("PumpHeaderAmount: " + ((MotherboardComponent)component).PumpHeaderAmount);

                        if (motherboardDto.PumpHeaderAmount == 0)
                            ((MotherboardComponent)component).PumpHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).PumpHeaderAmount = motherboardDto.PumpHeaderAmount;
                    }
                    if (motherboardDto.CPUOptionalFanHeaderAmount != null)
                    {
                        changedFields.Add("CPUOptionalFanHeaderAmount: " + ((MotherboardComponent)component).CPUOptionalFanHeaderAmount);

                        if (motherboardDto.CPUOptionalFanHeaderAmount == 0)
                            ((MotherboardComponent)component).CPUOptionalFanHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).CPUOptionalFanHeaderAmount = motherboardDto.CPUOptionalFanHeaderAmount;
                    }
                    if (motherboardDto.ARGB5vHeaderAmount != null)
                    {
                        changedFields.Add("ARGB5vHeaderAmount: " + ((MotherboardComponent)component).ARGB5vHeaderAmount);

                        if (motherboardDto.ARGB5vHeaderAmount == 0)
                            ((MotherboardComponent)component).ARGB5vHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).ARGB5vHeaderAmount = motherboardDto.ARGB5vHeaderAmount;
                    }
                    if (motherboardDto.RGB12vHeaderAmount != null)
                    {
                        changedFields.Add("RGB12vHeaderAmount: " + ((MotherboardComponent)component).RGB12vHeaderAmount);

                        if (motherboardDto.RGB12vHeaderAmount == 0)
                            ((MotherboardComponent)component).RGB12vHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).RGB12vHeaderAmount = motherboardDto.RGB12vHeaderAmount;
                    }
                    if (motherboardDto.HasPowerButtonHeader != null)
                    {
                        changedFields.Add("HasPowerButtonHeader: " + ((MotherboardComponent)component).HasPowerButtonHeader);

                        ((MotherboardComponent)component).HasPowerButtonHeader = (bool)motherboardDto.HasPowerButtonHeader;
                    }
                    if (motherboardDto.HasResetButtonHeader != null)
                    {
                        changedFields.Add("HasResetButtonHeader: " + ((MotherboardComponent)component).HasResetButtonHeader);

                        ((MotherboardComponent)component).HasResetButtonHeader = (bool)motherboardDto.HasResetButtonHeader;
                    }
                    if (motherboardDto.HasPowerLEDHeader != null)
                    {
                        changedFields.Add("HasPowerLEDHeader: " + ((MotherboardComponent)component).HasPowerLEDHeader);

                        ((MotherboardComponent)component).HasPowerLEDHeader = (bool)motherboardDto.HasPowerLEDHeader;
                    }
                    if (motherboardDto.HasHDDLEDHeader != null)
                    {
                        changedFields.Add("HasHDDLEDHeader: " + ((MotherboardComponent)component).HasHDDLEDHeader);

                        ((MotherboardComponent)component).HasHDDLEDHeader = (bool)motherboardDto.HasHDDLEDHeader;
                    }
                    if (motherboardDto.TemperatureSensorHeaderAmount != null)
                    {
                        changedFields.Add("TemperatureSensorHeaderAmount: " + ((MotherboardComponent)component).TemperatureSensorHeaderAmount);

                        if (motherboardDto.TemperatureSensorHeaderAmount == 0)
                            ((MotherboardComponent)component).TemperatureSensorHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).TemperatureSensorHeaderAmount = motherboardDto.TemperatureSensorHeaderAmount;
                    }
                    if (motherboardDto.ThunderboltHeaderAmount != null)
                    {
                        changedFields.Add("ThunderboltHeaderAmount: " + ((MotherboardComponent)component).ThunderboltHeaderAmount);

                        if (motherboardDto.ThunderboltHeaderAmount == 0)
                            ((MotherboardComponent)component).ThunderboltHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).ThunderboltHeaderAmount = motherboardDto.ThunderboltHeaderAmount;
                    }
                    if (motherboardDto.COMPortHeaderAmount != null)
                    {
                        changedFields.Add("COMPortHeaderAmount: " + ((MotherboardComponent)component).COMPortHeaderAmount);

                        if (motherboardDto.COMPortHeaderAmount == 0)
                            ((MotherboardComponent)component).COMPortHeaderAmount = null;
                        else
                            ((MotherboardComponent)component).COMPortHeaderAmount = motherboardDto.COMPortHeaderAmount;
                    }
                    if (motherboardDto.MainPowerType != null)
                    {
                        changedFields.Add("MainPowerType: " + ((MotherboardComponent)component).MainPowerType);

                        if (string.IsNullOrWhiteSpace(motherboardDto.MainPowerType))
                            ((MotherboardComponent)component).MainPowerType = null;
                        else
                            ((MotherboardComponent)component).MainPowerType = motherboardDto.MainPowerType;
                    }
                    if (motherboardDto.HasECCSupport != null)
                    {
                        changedFields.Add("HasECCSupport: " + ((MotherboardComponent)component).HasECCSupport);

                        ((MotherboardComponent)component).HasECCSupport = (bool)motherboardDto.HasECCSupport;
                    }
                    if (motherboardDto.HasRAIDSupport != null)
                    {
                        changedFields.Add("HasRAIDSupport: " + ((MotherboardComponent)component).HasRAIDSupport);

                        ((MotherboardComponent)component).HasRAIDSupport = (bool)motherboardDto.HasRAIDSupport;
                    }
                    if (motherboardDto.HasFlashback != null)
                    {
                        changedFields.Add("HasFlashback: " + ((MotherboardComponent)component).HasFlashback);

                        ((MotherboardComponent)component).HasFlashback = (bool)motherboardDto.HasFlashback;
                    }
                    if (motherboardDto.HasCMOS != null)
                    {
                        changedFields.Add("HasCMOS: " + ((MotherboardComponent)component).HasCMOS);

                        ((MotherboardComponent)component).HasCMOS = (bool)motherboardDto.HasCMOS;
                    }
                    if (!string.IsNullOrWhiteSpace(motherboardDto.AudioChipset))
                    {
                        changedFields.Add("AudioChipset: " + ((MotherboardComponent)component).AudioChipset);

                        ((MotherboardComponent)component).AudioChipset = motherboardDto.AudioChipset;
                    }
                    if (motherboardDto.MaxAudioChannels != null)
                    {
                        changedFields.Add("MaxAudioChannels: " + ((MotherboardComponent)component).MaxAudioChannels);

                        ((MotherboardComponent)component).MaxAudioChannels = (decimal)motherboardDto.MaxAudioChannels;
                    }
                    break;
                }
                case UpdatePowerSupplyComponentDto powerSupplyDto:
                {
                    if (powerSupplyDto.PowerOutput != null)
                    {
                        changedFields.Add("PowerOutput: " + ((PowerSupplyComponent)component).PowerOutput);

                        ((PowerSupplyComponent)component).PowerOutput = (decimal)powerSupplyDto.PowerOutput;
                    }
                    if (!string.IsNullOrWhiteSpace(powerSupplyDto.FormFactor))
                    {
                        changedFields.Add("FormFactor: " + ((PowerSupplyComponent)component).FormFactor);

                        ((PowerSupplyComponent)component).FormFactor = powerSupplyDto.FormFactor;
                    }
                    if (powerSupplyDto.EfficiencyRating != null)
                    {
                        changedFields.Add("EfficiencyRating: " + ((PowerSupplyComponent)component).PowerOutput);

                        if (string.IsNullOrWhiteSpace(powerSupplyDto.EfficiencyRating))
                            ((PowerSupplyComponent)component).EfficiencyRating = null;
                        else
                            ((PowerSupplyComponent)component).EfficiencyRating = powerSupplyDto.EfficiencyRating;
                    }
                    if (!string.IsNullOrWhiteSpace(powerSupplyDto.ModularityType))
                    {
                        changedFields.Add("ModularityType: " + ((PowerSupplyComponent)component).ModularityType);

                        ((PowerSupplyComponent)component).ModularityType = powerSupplyDto.ModularityType;
                    }
                    if (powerSupplyDto.Length != null)
                    {
                        changedFields.Add("Length: " + ((PowerSupplyComponent)component).Length);

                        ((PowerSupplyComponent)component).Length = (decimal)powerSupplyDto.Length;
                    }
                    if (powerSupplyDto.IsFanless != null)
                    {
                        changedFields.Add("IsFanless: " + ((PowerSupplyComponent)component).IsFanless);

                        ((PowerSupplyComponent)component).IsFanless = (bool)powerSupplyDto.IsFanless;
                    }
                    break;
                }
                case UpdateStorageComponentDto storageDto:
                {
                    if (!string.IsNullOrWhiteSpace(storageDto.Series))
                    {
                        changedFields.Add("Series: " + ((StorageComponent)component).Series);

                        ((StorageComponent)component).Series = storageDto.Series;
                    }
                    if (storageDto.Capacity != null)
                    {
                        changedFields.Add("Capacity: " + ((StorageComponent)component).Capacity);

                        ((StorageComponent)component).Capacity = (decimal)storageDto.Capacity;
                    }
                    if (!string.IsNullOrWhiteSpace(storageDto.DriveType))
                    {
                        changedFields.Add("DriveType: " + ((StorageComponent)component).DriveType);

                        ((StorageComponent)component).DriveType = storageDto.DriveType;
                    }
                    if (!string.IsNullOrWhiteSpace(storageDto.FormFactor))
                    {
                        changedFields.Add("FormFactor: " + ((StorageComponent)component).FormFactor);

                        ((StorageComponent)component).FormFactor = storageDto.FormFactor;
                    }
                    if (storageDto.HasNVMe != null)
                    {
                        changedFields.Add("HasNVMe: " + ((StorageComponent)component).HasNVMe);

                        ((StorageComponent)component).HasNVMe = (bool)storageDto.HasNVMe;
                    }
                    break;
                }
            };

            //Update base component fields
            if (!string.IsNullOrWhiteSpace(dto.Name))
            {
                changedFields.Add("Name: " + component.Name);

                component.Name = dto.Name;
            }
            if (!string.IsNullOrWhiteSpace(dto.Manufacturer))
            {
                changedFields.Add("Manufacturer: " + component.Manufacturer);

                component.Manufacturer = dto.Manufacturer;
            }
            if (dto.Release != null)
            {
                changedFields.Add("Release: " + component.Release);

                if (dto.Release == DateTime.MinValue)
                    component.Release = null;
                else
                    component.Release = (DateTime)dto.Release;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + component.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    component.Note = null;
                else
                    component.Note = dto.Note;
            }

            //Update edit timestamp
            component.LastEditedAt = DateTime.UtcNow;

            //Update the component
            _db.Components.Update(component);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Component",
                ip,
                component.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - Type: {component.Type}, {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("component.updated", new
            {
                componentId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { component = "Component updated successfully!" });
        }

        //API endpoint for getting the Component specified by id,
        //different level of information returned based on privileges
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BaseComponentResponseDto>> GetComponent(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the component to return
            var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == id);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Component",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Component"
                );

                //Return not found response
                return NotFound(new { component = "Component not found!" });
            }

            //Declare the response variable
            BaseComponentResponseDto response;

            //Log Description string declaration
            string logDescription;

            //Return an invalid response if try/catch statement catches a type assignment error
            try
            {
                //Create a component to add
                response = component switch
                {
                    CaseComponent caseComponent => new CaseComponentResponseDto
                    {
                        Name = caseComponent.Name,
                        Manufacturer = caseComponent.Manufacturer,
                        Release = caseComponent.Release,
                        Type = caseComponent.Type,
                        FormFactor = caseComponent.FormFactor,
                        PowerSupplyShrouded = caseComponent.PowerSupplyShrouded,
                        PowerSupplyAmount = caseComponent.PowerSupplyAmount,
                        HasTransparentSidePanel = caseComponent.HasTransparentSidePanel,
                        SidePanelType = caseComponent.SidePanelType,
                        MaxVideoCardLength = caseComponent.MaxVideoCardLength,
                        MaxCPUCoolerHeight = caseComponent.MaxCPUCoolerHeight,
                        Internal35BayAmount = caseComponent.Internal35BayAmount,
                        Internal25BayAmount = caseComponent.Internal25BayAmount,
                        External35BayAmount = caseComponent.External35BayAmount,
                        External525BayAmount = caseComponent.External525BayAmount,
                        ExpansionSlotAmount = caseComponent.ExpansionSlotAmount,
                        Dimensions = caseComponent.Dimensions,
                        Weight = caseComponent.Weight,
                        SupportsRearConnectingMotherboard = caseComponent.SupportsRearConnectingMotherboard
                    },
                    CaseFanComponent caseFanComponent => new CaseFanComponentResponseDto
                    {
                        Name = caseFanComponent.Name,
                        Manufacturer = caseFanComponent.Manufacturer,
                        Release = caseFanComponent.Release,
                        Type = caseFanComponent.Type,
                        Size = caseFanComponent.Size,
                        Quantity = caseFanComponent.Quantity,
                        MinAirflow = caseFanComponent.MinAirflow,
                        MaxAirflow = caseFanComponent.MaxAirflow,
                        MinNoiseLevel = caseFanComponent.MinNoiseLevel,
                        MaxNoiseLevel = caseFanComponent.MaxNoiseLevel,
                        PulseWidthModulation = caseFanComponent.PulseWidthModulation,
                        LEDType = caseFanComponent.LEDType,
                        ConnectorType = caseFanComponent.ConnectorType,
                        ControllerType = caseFanComponent.ControllerType,
                        StaticPressureAmount = caseFanComponent.StaticPressureAmount,
                        FlowDirection = caseFanComponent.FlowDirection
                    },
                    CoolerComponent coolerComponent => new CoolerComponentResponseDto
                    {
                        Name = coolerComponent.Name,
                        Manufacturer = coolerComponent.Manufacturer,
                        Release = coolerComponent.Release,
                        Type = coolerComponent.Type,
                        MinFanRotationSpeed = coolerComponent.MinFanRotationSpeed,
                        MaxFanRotationSpeed = coolerComponent.MaxFanRotationSpeed,
                        MinNoiseLevel = coolerComponent.MinNoiseLevel,
                        MaxNoiseLevel = coolerComponent.MaxNoiseLevel,
                        Height = coolerComponent.Height,
                        IsWaterCooled = coolerComponent.IsWaterCooled,
                        RadiatorSize = coolerComponent.RadiatorSize,
                        CanOperateFanless = coolerComponent.CanOperateFanless,
                        FanSize = coolerComponent.FanSize,
                        FanQuantity = coolerComponent.FanQuantity
                    },
                    CPUComponent cpuComponent => new CPUComponentResponseDto
                    {
                        Name = cpuComponent.Name,
                        Manufacturer = cpuComponent.Manufacturer,
                        Release = cpuComponent.Release,
                        Type = cpuComponent.Type,
                        Series = cpuComponent.Series,
                        Microarchitecture = cpuComponent.Microarchitecture,
                        CoreFamily = cpuComponent.CoreFamily,
                        SocketType = cpuComponent.SocketType,
                        CoreTotal = cpuComponent.CoreTotal,
                        PerformanceAmount = cpuComponent.PerformanceAmount,
                        EfficiencyAmount = cpuComponent.EfficiencyAmount,
                        ThreadsAmount = cpuComponent.ThreadsAmount,
                        BasePerformanceSpeed = cpuComponent.BasePerformanceSpeed,
                        BoostPerformanceSpeed = cpuComponent.BoostPerformanceSpeed,
                        BaseEfficiencySpeed = cpuComponent.BaseEfficiencySpeed,
                        BoostEfficiencySpeed = cpuComponent.BoostEfficiencySpeed,
                        L1 = cpuComponent.L1,
                        L2 = cpuComponent.L2,
                        L3 = cpuComponent.L3,
                        L4 = cpuComponent.L4,
                        IncludesCooler = cpuComponent.IncludesCooler,
                        Lithography = cpuComponent.Lithography,
                        SupportsSimultaneousMultithreading = cpuComponent.SupportsSimultaneousMultithreading,
                        MemoryType = cpuComponent.MemoryType,
                        PackagingType = cpuComponent.PackagingType,
                        SupportsErrorCorrectingCode = cpuComponent.SupportsErrorCorrectingCode,
                        ThermalDesignPower = cpuComponent.ThermalDesignPower
                    },
                    GPUComponent gpuComponent => new GPUComponentResponseDto
                    {
                        Name = gpuComponent.Name,
                        Manufacturer = gpuComponent.Manufacturer,
                        Release = gpuComponent.Release,
                        Type = gpuComponent.Type,
                        Chipset = gpuComponent.Chipset,
                        VideoMemoryAmount = gpuComponent.VideoMemoryAmount,
                        VideoMemoryType = gpuComponent.VideoMemoryType,
                        CoreBaseClockSpeed = gpuComponent.CoreBaseClockSpeed,
                        CoreBoostClockSpeed = gpuComponent.CoreBoostClockSpeed,
                        CoreCount = gpuComponent.CoreCount,
                        EffectiveMemoryClockSpeed = gpuComponent.EffectiveMemoryClockSpeed,
                        MemoryBusWidth = gpuComponent.MemoryBusWidth,
                        FrameSync = gpuComponent.FrameSync,
                        Length = gpuComponent.Length,
                        ThermalDesignPower = gpuComponent.ThermalDesignPower,
                        CaseExpansionSlotWidth = gpuComponent.CaseExpansionSlotWidth,
                        TotalSlotWidth = gpuComponent.TotalSlotWidth,
                        CoolingType = gpuComponent.CoolingType
                    },
                    MemoryComponent memoryComponent => new MemoryComponentResponseDto
                    {
                        Name = memoryComponent.Name,
                        Manufacturer = memoryComponent.Manufacturer,
                        Release = memoryComponent.Release,
                        Type = memoryComponent.Type,
                        Speed = memoryComponent.Speed,
                        RAMType = memoryComponent.RAMType,
                        FormFactor = memoryComponent.FormFactor,
                        Capacity = memoryComponent.Capacity,
                        CASLatency = memoryComponent.CASLatency,
                        Timings = memoryComponent.Timings,
                        ModuleQuantity = memoryComponent.ModuleQuantity,
                        ModuleCapacity = memoryComponent.ModuleCapacity,
                        ErrorCorrectingCode = memoryComponent.ErrorCorrectingCode,
                        RegisteredType = memoryComponent.RegisteredType,
                        HaveHeatSpreader = memoryComponent.HaveHeatSpreader,
                        HaveRGB = memoryComponent.HaveRGB,
                        Height = memoryComponent.Height,
                        Voltage = memoryComponent.Voltage
                    },
                    MonitorComponent monitorComponent => new MonitorComponentResponseDto
                    {
                        Name = monitorComponent.Name,
                        Manufacturer = monitorComponent.Manufacturer,
                        Release = monitorComponent.Release,
                        Type = monitorComponent.Type,
                        ScreenSize = monitorComponent.ScreenSize,
                        HorizontalResolution = monitorComponent.HorizontalResolution,
                        VerticalResolution = monitorComponent.VerticalResolution,
                        MaxRefreshRate = monitorComponent.MaxRefreshRate,
                        PanelType = monitorComponent.PanelType,
                        ResponseTime = monitorComponent.ResponseTime,
                        ViewingAngle = monitorComponent.ViewingAngle,
                        AspectRatio = monitorComponent.AspectRatio,
                        MaxBrightness = monitorComponent.MaxBrightness,
                        HighDynamicRangeType = monitorComponent.HighDynamicRangeType,
                        AdaptiveSyncType = monitorComponent.AdaptiveSyncType
                    },
                    MotherboardComponent motherboardComponent => new MotherboardComponentResponseDto
                    {
                        Name = motherboardComponent.Name,
                        Manufacturer = motherboardComponent.Manufacturer,
                        Release = motherboardComponent.Release,
                        Type = motherboardComponent.Type,
                        SocketType = motherboardComponent.SocketType,
                        FormFactor = motherboardComponent.FormFactor,
                        ChipsetType = motherboardComponent.ChipsetType,
                        RAMType = motherboardComponent.RAMType,
                        RAMSlotsAmount = motherboardComponent.RAMSlotsAmount,
                        MaxRAMAmount = motherboardComponent.MaxRAMAmount,
                        SerialATAttachment6GBsAmount = motherboardComponent.SerialATAttachment6GBsAmount,
                        SerialATAttachment3GBsAmount = motherboardComponent.SerialATAttachment3GBsAmount,
                        U2PortAmount = motherboardComponent.U2PortAmount,
                        WirelessNetworkingStandard = motherboardComponent.WirelessNetworkingStandard,
                        CPUFanHeaderAmount = motherboardComponent.CPUFanHeaderAmount,
                        CaseFanHeaderAmount = motherboardComponent.CaseFanHeaderAmount,
                        PumpHeaderAmount = motherboardComponent.PumpHeaderAmount,
                        CPUOptionalFanHeaderAmount = motherboardComponent.CPUOptionalFanHeaderAmount,
                        ARGB5vHeaderAmount = motherboardComponent.ARGB5vHeaderAmount,
                        RGB12vHeaderAmount = motherboardComponent.RGB12vHeaderAmount,
                        HasPowerButtonHeader = motherboardComponent.HasPowerButtonHeader,
                        HasResetButtonHeader = motherboardComponent.HasResetButtonHeader,
                        HasPowerLEDHeader = motherboardComponent.HasPowerLEDHeader,
                        HasHDDLEDHeader = motherboardComponent.HasHDDLEDHeader,
                        TemperatureSensorHeaderAmount = motherboardComponent.TemperatureSensorHeaderAmount,
                        ThunderboltHeaderAmount = motherboardComponent.ThunderboltHeaderAmount,
                        COMPortHeaderAmount = motherboardComponent.COMPortHeaderAmount,
                        MainPowerType = motherboardComponent.MainPowerType,
                        HasECCSupport = motherboardComponent.HasECCSupport,
                        HasRAIDSupport = motherboardComponent.HasRAIDSupport,
                        HasFlashback = motherboardComponent.HasFlashback,
                        HasCMOS = motherboardComponent.HasCMOS,
                        AudioChipset = motherboardComponent.AudioChipset,
                        MaxAudioChannels = motherboardComponent.MaxAudioChannels
                    },
                    PowerSupplyComponent powerSupplyComponent => new PowerSupplyComponentResponseDto
                    {
                        Name = powerSupplyComponent.Name,
                        Manufacturer = powerSupplyComponent.Manufacturer,
                        Release = powerSupplyComponent.Release,
                        Type = powerSupplyComponent.Type,
                        PowerOutput = powerSupplyComponent.PowerOutput,
                        FormFactor = powerSupplyComponent.FormFactor,
                        EfficiencyRating = powerSupplyComponent.EfficiencyRating,
                        ModularityType = powerSupplyComponent.ModularityType,
                        Length = powerSupplyComponent.Length,
                        IsFanless = powerSupplyComponent.IsFanless
                    },
                    StorageComponent storageComponent => new StorageComponentResponseDto
                    {
                        Name = storageComponent.Name,
                        Manufacturer = storageComponent.Manufacturer,
                        Release = storageComponent.Release,
                        Type = storageComponent.Type,
                        Series = storageComponent.Series,
                        Capacity = storageComponent.Capacity,
                        DriveType = storageComponent.DriveType,
                        FormFactor = storageComponent.FormFactor,
                        Interface = storageComponent.Interface,
                        HasNVMe = storageComponent.HasNVMe
                    },
                    _ => throw new NotImplementedException("Invalid Component Type"),
                };
            }
            catch (Exception ex)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Component",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"Operation Failed - {ex}"
                );

                //Return not found response
                return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid Component Type!", detail = ex.Message });
            }

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Add admin fields
                response.DatabaseEntryAt = component.DatabaseEntryAt;
                response.LastEditedAt = component.LastEditedAt;
                response.Note = component.Note;
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Component",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("component.got", new
            {
                componentId = id,
                gotBy = currentUserId
            });

            //Return the component
            return Ok(response);
        }

        //API endpoint for getting Components with pagination and search,
        //different level of information returned based on privileges
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BaseComponentResponseDto>>> GetComponents([FromBody] GetBaseComponentDto dto)
        {
            //Get component id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Components.AsNoTracking();

            //Filter by Base Component class variables
            if (dto.Name != null)
            {
                query = query.Where(c => dto.Name.Contains(c.Name));
            }
            if (dto.Manufacturer != null)
            {
                query = query.Where(c => dto.Manufacturer.Contains(c.Manufacturer));
            }
            if (dto.ReleaseStart != null)
            {
                query = query.Where(c => c.Release >= dto.ReleaseStart);
            }
            if (dto.ReleaseEnd != null)
            {
                query = query.Where(c => c.Release <= dto.ReleaseEnd);
            }

            //Apply search for the Base Component
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, c => c.Name, c => c.Manufacturer, c => c.Release!, c => c.Type);
            }

            //Filter by the specific subclass variables
            switch (dto)
            {
                case GetCaseComponentDto caseDto:
                {
                    //Create a subquery based on the Case type
                    var caseQuery = query.OfType<CaseComponent>();

                    //Filter by Case Component class variables
                    caseQuery = caseQuery.Where(c =>
                        (caseDto.FormFactor == null || caseDto.FormFactor.Contains(c.FormFactor)) &&
                        (caseDto.PowerSupplyShrouded == null || caseDto.PowerSupplyShrouded == c.PowerSupplyShrouded) &&
                        (caseDto.PowerSupplyAmountStart == null || caseDto.PowerSupplyAmountStart <= c.PowerSupplyAmount) &&
                        (caseDto.PowerSupplyAmountEnd == null || caseDto.PowerSupplyAmountEnd >= c.PowerSupplyAmount) &&
                        (caseDto.HasTransparentSidePanel == null || caseDto.HasTransparentSidePanel == c.HasTransparentSidePanel) &&
                        (caseDto.SidePanelType == null || (c.SidePanelType != null && caseDto.SidePanelType.Contains(c.SidePanelType))) &&
                        (caseDto.MaxVideoCardLengthStart == null || caseDto.MaxVideoCardLengthStart <= c.MaxVideoCardLength) &&
                        (caseDto.MaxVideoCardLengthEnd == null || caseDto.MaxVideoCardLengthEnd >= c.MaxVideoCardLength) &&
                        (caseDto.MaxCPUCoolerHeightStart == null || caseDto.MaxCPUCoolerHeightStart <= c.MaxCPUCoolerHeight) &&
                        (caseDto.MaxCPUCoolerHeightEnd == null || caseDto.MaxCPUCoolerHeightEnd >= c.MaxCPUCoolerHeight) &&
                        (caseDto.Internal35BayAmountStart == null || caseDto.Internal35BayAmountStart <= c.Internal35BayAmount) &&
                        (caseDto.Internal35BayAmountEnd == null || caseDto.Internal35BayAmountEnd >= c.Internal35BayAmount) &&
                        (caseDto.Internal25BayAmountStart == null || caseDto.Internal25BayAmountStart <= c.Internal25BayAmount) &&
                        (caseDto.Internal25BayAmountEnd == null || caseDto.Internal25BayAmountEnd >= c.Internal25BayAmount) &&
                        (caseDto.External35BayAmountStart == null || caseDto.External35BayAmountStart <= c.External35BayAmount) &&
                        (caseDto.External35BayAmountEnd == null || caseDto.External35BayAmountEnd >= c.External35BayAmount) &&
                        (caseDto.External525BayAmountStart == null || caseDto.External525BayAmountStart <= c.External525BayAmount) &&
                        (caseDto.External525BayAmountEnd == null || caseDto.External525BayAmountEnd >= c.External525BayAmount) &&
                        (caseDto.ExpansionSlotAmountStart == null || caseDto.ExpansionSlotAmountStart <= c.ExpansionSlotAmount) &&
                        (caseDto.ExpansionSlotAmountEnd == null || caseDto.ExpansionSlotAmountEnd >= c.ExpansionSlotAmount) &&
                        (caseDto.DepthStart == null || caseDto.DepthStart <= c.Dimensions.Depth) &&
                        (caseDto.DepthEnd == null || caseDto.DepthEnd >= c.Dimensions.Depth) &&
                        (caseDto.HeightStart == null || caseDto.HeightStart <= c.Dimensions.Height) &&
                        (caseDto.HeightEnd == null || caseDto.HeightEnd >= c.Dimensions.Height) &&
                        (caseDto.WidthStart == null || caseDto.WidthStart <= c.Dimensions.Width) &&
                        (caseDto.WidthEnd == null || caseDto.WidthEnd >= c.Dimensions.Width) &&
                        (caseDto.VolumeStart == null || caseDto.VolumeStart <= c.Volume) &&
                        (caseDto.VolumeEnd == null || caseDto.VolumeEnd >= c.Volume) &&
                        (caseDto.WeightStart == null || caseDto.WeightStart <= c.Weight) &&
                        (caseDto.WeightEnd == null || caseDto.WeightEnd >= c.Weight) &&
                        (caseDto.SupportsRearConnectingMotherboard == null || caseDto.SupportsRearConnectingMotherboard == c.SupportsRearConnectingMotherboard)
                    );

                    //Apply search for the Case Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        caseQuery = caseQuery.Search(dto.Query, c => c.FormFactor);
                    }

                    query = caseQuery;

                    break;
                }
                case GetCaseFanComponentDto caseFanDto:
                {
                    //Create a subquery based on the CaseFan type
                    var caseFanQuery = query.OfType<CaseFanComponent>();
                        
                    //Filter by Case Fan Component class variables
                    caseFanQuery = caseFanQuery.Where(c =>
                        (caseFanDto.LEDType == null || (c.LEDType != null && caseFanDto.LEDType.Contains(c.LEDType))) &&
                        (caseFanDto.ConnectorType == null || (c.ConnectorType != null && caseFanDto.ConnectorType.Contains(c.ConnectorType))) &&
                        (caseFanDto.ControllerType == null || (c.ControllerType != null && caseFanDto.ControllerType.Contains(c.ControllerType))) &&
                        (caseFanDto.FlowDirection == null || caseFanDto.FlowDirection.Contains(c.FlowDirection)) &&
                        (caseFanDto.SizeStart == null || caseFanDto.SizeStart <= c.Size) &&
                        (caseFanDto.SizeEnd == null || caseFanDto.SizeEnd >= c.Size) &&
                        (caseFanDto.QuantityStart == null || caseFanDto.QuantityStart <= c.Quantity) &&
                        (caseFanDto.QuantityEnd == null || caseFanDto.QuantityEnd >= c.Quantity) &&
                        (caseFanDto.MinAirflowStart == null || caseFanDto.MinAirflowStart <= c.MinAirflow) &&
                        (caseFanDto.MinAirflowEnd == null || caseFanDto.MinAirflowEnd >= c.MinAirflow) &&
                        (caseFanDto.MaxAirflowStart == null || caseFanDto.MaxAirflowStart <= c.MaxAirflow) &&
                        (caseFanDto.MaxAirflowEnd == null || caseFanDto.MaxAirflowEnd >= c.MaxAirflow) &&
                        (caseFanDto.MinNoiseLevelStart == null || caseFanDto.MinNoiseLevelStart <= c.MinNoiseLevel) &&
                        (caseFanDto.MinNoiseLevelEnd == null || caseFanDto.MinNoiseLevelEnd >= c.MinNoiseLevel) &&
                        (caseFanDto.MaxNoiseLevelStart == null || caseFanDto.MaxNoiseLevelStart <= c.MaxNoiseLevel) &&
                        (caseFanDto.MaxNoiseLevelEnd == null || caseFanDto.MaxNoiseLevelEnd >= c.MaxNoiseLevel) &&
                        (caseFanDto.StaticPressureAmountStart == null || caseFanDto.StaticPressureAmountStart <= c.StaticPressureAmount) &&
                        (caseFanDto.StaticPressureAmountEnd == null || caseFanDto.StaticPressureAmountEnd >= c.StaticPressureAmount) &&
                        (caseFanDto.PulseWidthModulation == null || caseFanDto.PulseWidthModulation == c.PulseWidthModulation)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        caseFanQuery = caseFanQuery.Search(dto.Query, c => c.LEDType!, c => c.ConnectorType!, c => c.ControllerType!);
                    }

                    query = caseFanQuery;

                    break;
                }
                case GetCoolerComponentDto coolerDto:
                {
                    //Create a subquery based on the Cooler type
                    var coolerQuery = query.OfType<CoolerComponent>();
                        
                    //Filter by Cooler class variables
                    coolerQuery = coolerQuery.Where(c =>
                        (coolerDto.MinFanRotationSpeedStart == null || coolerDto.MinFanRotationSpeedStart <= c.MinFanRotationSpeed) &&
                        (coolerDto.MinFanRotationSpeedEnd == null || coolerDto.MinFanRotationSpeedEnd >= c.MinFanRotationSpeed) &&
                        (coolerDto.MaxFanRotationSpeedStart == null || coolerDto.MaxFanRotationSpeedStart <= c.MaxFanRotationSpeed) &&
                        (coolerDto.MaxFanRotationSpeedEnd == null || coolerDto.MaxFanRotationSpeedEnd >= c.MaxFanRotationSpeed) &&
                        (coolerDto.MinNoiseLevelStart == null || coolerDto.MinNoiseLevelStart <= c.MinNoiseLevel) &&
                        (coolerDto.MinNoiseLevelEnd == null || coolerDto.MinNoiseLevelEnd >= c.MinNoiseLevel) &&
                        (coolerDto.MaxNoiseLevelStart == null || coolerDto.MaxNoiseLevelStart <= c.MaxNoiseLevel) &&
                        (coolerDto.MaxNoiseLevelEnd == null || coolerDto.MaxNoiseLevelEnd >= c.MaxNoiseLevel) &&
                        (coolerDto.HeightStart == null || coolerDto.HeightStart <= c.Height) &&
                        (coolerDto.HeightEnd == null || coolerDto.HeightEnd >= c.Height) &&
                        (coolerDto.RadiatorSizeStart == null || coolerDto.RadiatorSizeStart <= c.RadiatorSize) &&
                        (coolerDto.RadiatorSizeEnd == null || coolerDto.RadiatorSizeEnd >= c.RadiatorSize) &&
                        (coolerDto.FanSizeStart == null || coolerDto.FanSizeStart <= c.FanSize) &&
                        (coolerDto.FanSizeEnd == null || coolerDto.FanSizeEnd >= c.FanSize) &&
                        (coolerDto.FanQuantityStart == null || coolerDto.FanQuantityStart <= c.FanQuantity) &&
                        (coolerDto.FanQuantityEnd == null || coolerDto.FanQuantityEnd >= c.FanQuantity) &&
                        (coolerDto.IsWaterCooled == null || coolerDto.IsWaterCooled == c.IsWaterCooled) &&
                        (coolerDto.CanOperateFanless == null || coolerDto.CanOperateFanless == c.CanOperateFanless)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        //coolerQuery = coolerQuery.Search(dto.Query, );
                    }

                    query = coolerQuery;

                    break;
                }
                case GetCPUComponentDto cpuDto:
                {
                    //Create a subquery based on the CPU type
                    var cpuQuery = query.OfType<CPUComponent>();
                        
                    //Filter by CPU class variables
                    cpuQuery = cpuQuery.Where(c =>
                        (cpuDto.Series == null || cpuDto.Series.Contains(c.Series)) &&
                        (cpuDto.Microarchitecture == null || cpuDto.Microarchitecture.Contains(c.Microarchitecture)) &&
                        (cpuDto.CoreFamily == null || cpuDto.CoreFamily.Contains(c.CoreFamily)) &&
                        (cpuDto.SocketType == null || cpuDto.SocketType.Contains(c.SocketType)) &&
                        (cpuDto.Lithography == null || cpuDto.Lithography.Contains(c.Lithography)) &&
                        (cpuDto.MemoryType == null || cpuDto.MemoryType.Contains(c.MemoryType)) &&
                        (cpuDto.PackagingType == null || cpuDto.PackagingType.Contains(c.PackagingType)) &&
                        (cpuDto.IncludesCooler == null || cpuDto.IncludesCooler == c.IncludesCooler) &&
                        (cpuDto.SupportsSimultaneousMultithreading == null || cpuDto.SupportsSimultaneousMultithreading == c.SupportsSimultaneousMultithreading) &&
                        (cpuDto.SupportsErrorCorrectingCode == null || cpuDto.SupportsErrorCorrectingCode == c.SupportsErrorCorrectingCode) &&
                        (cpuDto.CoreTotalStart == null || cpuDto.CoreTotalStart <= c.CoreTotal) &&
                        (cpuDto.CoreTotalEnd == null || cpuDto.CoreTotalEnd >= c.CoreTotal) &&
                        (cpuDto.PerformanceAmountStart == null || cpuDto.PerformanceAmountStart <= c.PerformanceAmount) &&
                        (cpuDto.PerformanceAmountEnd == null || cpuDto.PerformanceAmountEnd >= c.PerformanceAmount) &&
                        (cpuDto.EfficiencyAmountStart == null || cpuDto.EfficiencyAmountStart <= c.EfficiencyAmount) &&
                        (cpuDto.EfficiencyAmountEnd == null || cpuDto.EfficiencyAmountEnd >= c.EfficiencyAmount) &&
                        (cpuDto.ThreadsAmountStart == null || cpuDto.ThreadsAmountStart <= c.ThreadsAmount) &&
                        (cpuDto.ThreadsAmountEnd == null || cpuDto.ThreadsAmountEnd >= c.ThreadsAmount) &&
                        (cpuDto.BasePerformanceSpeedStart == null || cpuDto.BasePerformanceSpeedStart <= c.BasePerformanceSpeed) &&
                        (cpuDto.BasePerformanceSpeedEnd == null || cpuDto.BasePerformanceSpeedEnd >= c.BasePerformanceSpeed) &&
                        (cpuDto.BoostPerformanceSpeedStart == null || cpuDto.BoostPerformanceSpeedStart <= c.BoostPerformanceSpeed) &&
                        (cpuDto.BoostPerformanceSpeedEnd == null || cpuDto.BoostPerformanceSpeedEnd >= c.BoostPerformanceSpeed) &&
                        (cpuDto.BaseEfficiencySpeedStart == null || cpuDto.BaseEfficiencySpeedStart <= c.BaseEfficiencySpeed) &&
                        (cpuDto.BaseEfficiencySpeedEnd == null || cpuDto.BaseEfficiencySpeedEnd >= c.BaseEfficiencySpeed) &&
                        (cpuDto.BoostEfficiencySpeedStart == null || cpuDto.BoostEfficiencySpeedStart <= c.BoostEfficiencySpeed) &&
                        (cpuDto.BoostEfficiencySpeedEnd == null || cpuDto.BoostEfficiencySpeedEnd >= c.BoostEfficiencySpeed) &&
                        (cpuDto.L1Start == null || cpuDto.L1Start <= c.L1) &&
                        (cpuDto.L1End == null || cpuDto.L1End >= c.L1) &&
                        (cpuDto.L2Start == null || cpuDto.L2Start <= c.L2) &&
                        (cpuDto.L2End == null || cpuDto.L2End >= c.L2) &&
                        (cpuDto.L3Start == null || cpuDto.L3Start <= c.L3) &&
                        (cpuDto.L3End == null || cpuDto.L3End >= c.L3) &&
                        (cpuDto.L4Start == null || cpuDto.L4Start <= c.L4) &&
                        (cpuDto.L4End == null || cpuDto.L4End >= c.L4) &&
                        (cpuDto.ThermalDesignPowerStart == null || cpuDto.ThermalDesignPowerStart <= c.ThermalDesignPower) &&
                        (cpuDto.ThermalDesignPowerEnd == null || cpuDto.ThermalDesignPowerEnd >= c.ThermalDesignPower)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        cpuQuery = cpuQuery.Search(dto.Query, c => c.Series, c => c.Microarchitecture, c => c.CoreFamily, c => c.SocketType, c => c.Lithography, c => c.MemoryType, c => c.PackagingType);
                    }

                    query = cpuQuery;

                    break;
                }
                case GetGPUComponentDto gpuDto:
                {
                    //Create a subquery based on the GPU type
                    var gpuQuery = query.OfType<GPUComponent>();
                        
                    //Filter by GPU Component class variables
                    gpuQuery = gpuQuery.Where(c =>
                        (gpuDto.VideoMemoryType == null || gpuDto.VideoMemoryType.Contains(c.VideoMemoryType)) &&
                        (gpuDto.CoolingType == null || gpuDto.CoolingType.Contains(c.CoolingType)) &&
                        (gpuDto.FrameSync == null || gpuDto.FrameSync.Contains(c.FrameSync)) &&
                        (gpuDto.VideoMemoryAmountStart == null || gpuDto.VideoMemoryAmountStart <= c.VideoMemoryAmount) &&
                        (gpuDto.VideoMemoryAmountEnd == null || gpuDto.VideoMemoryAmountEnd >= c.VideoMemoryAmount) &&
                        (gpuDto.CoreBaseClockSpeedStart == null || gpuDto.CoreBaseClockSpeedStart <= c.CoreBaseClockSpeed) &&
                        (gpuDto.CoreBaseClockSpeedEnd == null || gpuDto.CoreBaseClockSpeedEnd >= c.CoreBaseClockSpeed) &&
                        (gpuDto.CoreBoostClockSpeedStart == null || gpuDto.CoreBoostClockSpeedStart <= c.CoreBoostClockSpeed) &&
                        (gpuDto.CoreBoostClockSpeedEnd == null || gpuDto.CoreBoostClockSpeedEnd >= c.CoreBoostClockSpeed) &&
                        (gpuDto.CoreCountStart == null || gpuDto.CoreCountStart <= c.CoreCount) &&
                        (gpuDto.CoreCountEnd == null || gpuDto.CoreCountEnd >= c.CoreCount) &&
                        (gpuDto.EffectiveMemoryClockSpeedStart == null || gpuDto.EffectiveMemoryClockSpeedStart <= c.EffectiveMemoryClockSpeed) &&
                        (gpuDto.EffectiveMemoryClockSpeedEnd == null || gpuDto.EffectiveMemoryClockSpeedEnd >= c.EffectiveMemoryClockSpeed) &&
                        (gpuDto.MemoryBusWidthStart == null || gpuDto.MemoryBusWidthStart <= c.MemoryBusWidth) &&
                        (gpuDto.MemoryBusWidthEnd == null || gpuDto.MemoryBusWidthEnd >= c.MemoryBusWidth) &&
                        (gpuDto.LengthStart == null || gpuDto.LengthStart <= c.Length) &&
                        (gpuDto.LengthEnd == null || gpuDto.LengthEnd >= c.Length) &&
                        (gpuDto.ThermalDesignPowerStart == null || gpuDto.ThermalDesignPowerStart <= c.ThermalDesignPower) &&
                        (gpuDto.ThermalDesignPowerEnd == null || gpuDto.ThermalDesignPowerEnd >= c.ThermalDesignPower) &&
                        (gpuDto.CaseExpansionSlotWidthStart == null || gpuDto.CaseExpansionSlotWidthStart <= c.CaseExpansionSlotWidth) &&
                        (gpuDto.CaseExpansionSlotWidthEnd == null || gpuDto.CaseExpansionSlotWidthEnd >= c.CaseExpansionSlotWidth) &&
                        (gpuDto.TotalSlotWidthStart == null || gpuDto.TotalSlotWidthStart <= c.TotalSlotWidth) &&
                        (gpuDto.TotalSlotWidthEnd == null || gpuDto.TotalSlotWidthEnd >= c.TotalSlotWidth) &&
                        (gpuDto.ThermalDesignPowerStart == null || gpuDto.ThermalDesignPowerStart <= c.ThermalDesignPower) &&
                        (gpuDto.ThermalDesignPowerEnd == null || gpuDto.ThermalDesignPowerEnd >= c.ThermalDesignPower)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        gpuQuery = gpuQuery.Search(dto.Query, c => c.VideoMemoryType, c => c.CoolingType, c => c.FrameSync);
                    }

                    query = gpuQuery;

                    break;
                }
                case GetMemoryComponentDto memoryDto:
                {
                    //Create a subquery based on the Memory type
                    var memoryQuery = query.OfType<MemoryComponent>();
                        
                    //Filter by Memory Component class variables
                    memoryQuery = memoryQuery.Where(c =>
                        (memoryDto.RAMType == null || memoryDto.RAMType.Contains(c.RAMType)) &&
                        (memoryDto.FormFactor == null || memoryDto.FormFactor.Contains(c.FormFactor)) &&
                        (memoryDto.Timings == null || (c.Timings != null && memoryDto.Timings.Contains(c.Timings))) &&
                        (memoryDto.ErrorCorrectingCode == null || memoryDto.ErrorCorrectingCode.Contains(c.ErrorCorrectingCode)) &&
                        (memoryDto.RegisteredType == null || memoryDto.RegisteredType.Contains(c.RegisteredType)) &&
                        (memoryDto.HaveHeatSpreader == null || memoryDto.HaveHeatSpreader == c.HaveHeatSpreader) &&
                        (memoryDto.HaveRGB == null || memoryDto.HaveRGB == c.HaveRGB) &&
                        (memoryDto.SpeedStart == null || memoryDto.SpeedStart <= c.Speed) &&
                        (memoryDto.SpeedEnd == null || memoryDto.SpeedEnd >= c.Speed) &&
                        (memoryDto.CapacityStart == null || memoryDto.CapacityStart <= c.Capacity) &&
                        (memoryDto.CapacityEnd == null || memoryDto.CapacityEnd >= c.Capacity) &&
                        (memoryDto.CASLatencyStart == null || memoryDto.CASLatencyStart <= c.CASLatency) &&
                        (memoryDto.CASLatencyEnd == null || memoryDto.CASLatencyEnd >= c.CASLatency) &&
                        (memoryDto.ModuleQuantityStart == null || memoryDto.ModuleQuantityStart <= c.ModuleQuantity) &&
                        (memoryDto.ModuleQuantityEnd == null || memoryDto.ModuleQuantityEnd >= c.ModuleQuantity) &&
                        (memoryDto.ModuleCapacityStart == null || memoryDto.ModuleCapacityStart <= c.ModuleCapacity) &&
                        (memoryDto.ModuleCapacityEnd == null || memoryDto.ModuleCapacityEnd >= c.ModuleCapacity) &&
                        (memoryDto.HeightStart == null || memoryDto.HeightStart <= c.Height) &&
                        (memoryDto.HeightEnd == null || memoryDto.HeightEnd >= c.Height) &&
                        (memoryDto.VoltageStart == null || memoryDto.VoltageStart <= c.Voltage) &&
                        (memoryDto.VoltageEnd == null || memoryDto.VoltageEnd >= c.Voltage)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        memoryQuery = memoryQuery.Search(dto.Query, c => c.RAMType, c => c.FormFactor, c => c.Timings!, c => c.ErrorCorrectingCode, c => c.RegisteredType);
                    }

                    query = memoryQuery;

                    break;
                }
                case GetMonitorComponentDto monitorDto:
                {
                    //Create a subquery based on the Monitor type
                    var monitorQuery = query.OfType<MonitorComponent>();
                        
                    //Filter by Monitor Component class variables
                    monitorQuery = monitorQuery.Where(c =>
                        (monitorDto.PanelType == null || monitorDto.PanelType.Contains(c.PanelType)) &&
                        (monitorDto.ViewingAngle == null || monitorDto.ViewingAngle.Contains(c.ViewingAngle)) &&
                        (monitorDto.AspectRatio == null || monitorDto.AspectRatio.Contains(c.AspectRatio)) &&
                        (monitorDto.HighDynamicRangeType == null || (c.HighDynamicRangeType != null && monitorDto.HighDynamicRangeType.Contains(c.HighDynamicRangeType))) &&
                        (monitorDto.AdaptiveSyncType == null || monitorDto.AdaptiveSyncType.Contains(c.AdaptiveSyncType)) &&
                        (monitorDto.ScreenSizeStart == null || monitorDto.ScreenSizeStart <= c.ScreenSize) &&
                        (monitorDto.ScreenSizeEnd == null || monitorDto.ScreenSizeEnd >= c.ScreenSize) &&
                        (monitorDto.HorizontalResolutionStart == null || monitorDto.HorizontalResolutionStart <= c.HorizontalResolution) &&
                        (monitorDto.HorizontalResolutionEnd == null || monitorDto.HorizontalResolutionEnd >= c.HorizontalResolution) &&
                        (monitorDto.VerticalResolutionStart == null || monitorDto.VerticalResolutionStart <= c.VerticalResolution) &&
                        (monitorDto.VerticalResolutionEnd == null || monitorDto.VerticalResolutionEnd >= c.VerticalResolution) &&
                        (monitorDto.MaxRefreshRateStart == null || monitorDto.MaxRefreshRateStart <= c.MaxRefreshRate) &&
                        (monitorDto.MaxRefreshRateEnd == null || monitorDto.MaxRefreshRateEnd >= c.MaxRefreshRate) &&
                        (monitorDto.ResponseTimeStart == null || monitorDto.ResponseTimeStart <= c.ResponseTime) &&
                        (monitorDto.ResponseTimeEnd == null || monitorDto.ResponseTimeEnd >= c.ResponseTime) &&
                        (monitorDto.ViewingAngleStart == null || MonitorParseHelper.ParseViewingAngle(monitorDto.ViewingAngleStart) <= MonitorParseHelper.ParseViewingAngle(c.ViewingAngle)) &&
                        (monitorDto.ViewingAngleEnd == null || MonitorParseHelper.ParseViewingAngle(monitorDto.ViewingAngleEnd) >= MonitorParseHelper.ParseViewingAngle(c.ViewingAngle)) &&
                        (monitorDto.AspectRatioStart == null || MonitorParseHelper.ParseViewingAngle(monitorDto.AspectRatioStart) <= MonitorParseHelper.ParseViewingAngle(c.AspectRatio)) &&
                        (monitorDto.AspectRatioEnd == null || MonitorParseHelper.ParseViewingAngle(monitorDto.AspectRatioEnd) >= MonitorParseHelper.ParseViewingAngle(c.AspectRatio)) &&
                        (monitorDto.MaxBrightnessStart == null || monitorDto.MaxBrightnessStart <= c.MaxBrightness) &&
                        (monitorDto.MaxBrightnessEnd == null || monitorDto.MaxBrightnessEnd >= c.MaxBrightness)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        monitorQuery = monitorQuery.Search(dto.Query, c => c.PanelType, c => c.ViewingAngle, c => c.AspectRatio, c => c.HighDynamicRangeType!, c => c.AdaptiveSyncType);
                    }

                    query = monitorQuery;

                    break;
                }
                case GetMotherboardComponentDto motherboardDto:
                {
                    //Create a subquery based on the Motherboard type
                    var motherboardQuery = query.OfType<MotherboardComponent>();
                        
                    //Filter by Motherboard Component class variables
                    motherboardQuery = motherboardQuery.Where(c =>
                        (motherboardDto.SocketType == null || motherboardDto.SocketType.Contains(c.SocketType)) &&
                        (motherboardDto.FormFactor == null || motherboardDto.FormFactor.Contains(c.FormFactor)) &&
                        (motherboardDto.ChipsetType == null || motherboardDto.ChipsetType.Contains(c.ChipsetType)) &&
                        (motherboardDto.RAMType == null || motherboardDto.RAMType.Contains(c.RAMType)) &&
                        (motherboardDto.AudioChipset == null || motherboardDto.AudioChipset.Contains(c.AudioChipset)) &&
                        (motherboardDto.WirelessNetworkingStandard == null || motherboardDto.WirelessNetworkingStandard.Contains(c.WirelessNetworkingStandard)) &&
                        (motherboardDto.MainPowerType == null || (c.MainPowerType != null && motherboardDto.MainPowerType.Contains(c.MainPowerType))) &&
                        (motherboardDto.HasPowerButtonHeader == null || motherboardDto.HasPowerButtonHeader == c.HasPowerButtonHeader) &&
                        (motherboardDto.HasResetButtonHeader == null || motherboardDto.HasResetButtonHeader == c.HasResetButtonHeader) &&
                        (motherboardDto.HasPowerLEDHeader == null || motherboardDto.HasPowerLEDHeader == c.HasPowerLEDHeader) &&
                        (motherboardDto.HasHDDLEDHeader == null || motherboardDto.HasHDDLEDHeader == c.HasHDDLEDHeader) &&
                        (motherboardDto.HasECCSupport == null || motherboardDto.HasECCSupport == c.HasECCSupport) &&
                        (motherboardDto.HasRAIDSupport == null || motherboardDto.HasRAIDSupport == c.HasRAIDSupport) &&
                        (motherboardDto.HasFlashback == null || motherboardDto.HasFlashback == c.HasFlashback) &&
                        (motherboardDto.HasCMOS == null || motherboardDto.HasCMOS == c.HasCMOS) &&
                        (motherboardDto.RAMSlotsAmountStart == null || motherboardDto.RAMSlotsAmountStart <= c.RAMSlotsAmount) &&
                        (motherboardDto.RAMSlotsAmountEnd == null || motherboardDto.RAMSlotsAmountEnd >= c.RAMSlotsAmount) &&
                        (motherboardDto.MaxRAMAmountStart == null || motherboardDto.MaxRAMAmountStart <= c.MaxRAMAmount) &&
                        (motherboardDto.MaxRAMAmountEnd == null || motherboardDto.MaxRAMAmountEnd >= c.MaxRAMAmount) &&
                        (motherboardDto.SerialATAttachment6GBsAmountStart == null || motherboardDto.SerialATAttachment6GBsAmountStart <= c.SerialATAttachment6GBsAmount) &&
                        (motherboardDto.SerialATAttachment6GBsAmountEnd == null || motherboardDto.SerialATAttachment6GBsAmountEnd >= c.SerialATAttachment6GBsAmount) &&
                        (motherboardDto.SerialATAttachment3GBsAmountStart == null || motherboardDto.SerialATAttachment3GBsAmountStart <= c.SerialATAttachment3GBsAmount) &&
                        (motherboardDto.SerialATAttachment3GBsAmountEnd == null || motherboardDto.SerialATAttachment3GBsAmountEnd >= c.SerialATAttachment3GBsAmount) &&
                        (motherboardDto.U2PortAmountStart == null || motherboardDto.U2PortAmountStart <= c.U2PortAmount) &&
                        (motherboardDto.U2PortAmountEnd == null || motherboardDto.U2PortAmountEnd >= c.U2PortAmount) &&
                        (motherboardDto.CPUFanHeaderAmountStart == null || motherboardDto.CPUFanHeaderAmountStart <= c.CPUFanHeaderAmount) &&
                        (motherboardDto.CPUFanHeaderAmountEnd == null || motherboardDto.CPUFanHeaderAmountEnd >= c.CPUFanHeaderAmount) &&
                        (motherboardDto.CaseFanHeaderAmountStart == null || motherboardDto.CaseFanHeaderAmountStart <= c.CaseFanHeaderAmount) &&
                        (motherboardDto.CaseFanHeaderAmountEnd == null || motherboardDto.CaseFanHeaderAmountEnd >= c.CaseFanHeaderAmount) &&
                        (motherboardDto.PumpHeaderAmountStart == null || motherboardDto.PumpHeaderAmountStart <= c.PumpHeaderAmount) &&
                        (motherboardDto.PumpHeaderAmountEnd == null || motherboardDto.PumpHeaderAmountEnd >= c.PumpHeaderAmount) &&
                        (motherboardDto.CPUOptionalFanHeaderAmountStart == null || motherboardDto.CPUOptionalFanHeaderAmountStart <= c.CPUOptionalFanHeaderAmount) &&
                        (motherboardDto.CPUOptionalFanHeaderAmountEnd == null || motherboardDto.CPUOptionalFanHeaderAmountEnd >= c.CPUOptionalFanHeaderAmount) &&
                        (motherboardDto.ARGB5vHeaderAmountStart == null || motherboardDto.ARGB5vHeaderAmountStart <= c.ARGB5vHeaderAmount) &&
                        (motherboardDto.ARGB5vHeaderAmountEnd == null || motherboardDto.ARGB5vHeaderAmountEnd >= c.ARGB5vHeaderAmount) &&
                        (motherboardDto.RGB12vHeaderAmountStart == null || motherboardDto.RGB12vHeaderAmountStart <= c.RGB12vHeaderAmount) &&
                        (motherboardDto.RGB12vHeaderAmountEnd == null || motherboardDto.RGB12vHeaderAmountEnd >= c.RGB12vHeaderAmount) &&
                        (motherboardDto.TemperatureSensorHeaderAmountStart == null || motherboardDto.TemperatureSensorHeaderAmountStart <= c.TemperatureSensorHeaderAmount) &&
                        (motherboardDto.TemperatureSensorHeaderAmountEnd == null || motherboardDto.TemperatureSensorHeaderAmountEnd >= c.TemperatureSensorHeaderAmount) &&
                        (motherboardDto.ThunderboltHeaderAmountStart == null || motherboardDto.ThunderboltHeaderAmountStart <= c.ThunderboltHeaderAmount) &&
                        (motherboardDto.ThunderboltHeaderAmountEnd == null || motherboardDto.ThunderboltHeaderAmountEnd >= c.ThunderboltHeaderAmount) &&
                        (motherboardDto.COMPortHeaderAmountStart == null || motherboardDto.COMPortHeaderAmountStart <= c.COMPortHeaderAmount) &&
                        (motherboardDto.COMPortHeaderAmountEnd == null || motherboardDto.COMPortHeaderAmountEnd >= c.COMPortHeaderAmount) &&
                        (motherboardDto.MaxAudioChannelsStart == null || motherboardDto.MaxAudioChannelsStart <= c.MaxAudioChannels) &&
                        (motherboardDto.MaxAudioChannelsEnd == null || motherboardDto.MaxAudioChannelsEnd >= c.MaxAudioChannels)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        motherboardQuery = motherboardQuery.Search(dto.Query, c => c.SocketType, c => c.FormFactor, c => c.ChipsetType, c => c.RAMType, c => c.AudioChipset, c => c.WirelessNetworkingStandard, c => c.MainPowerType!);
                    }

                    query = motherboardQuery;

                    break;
                }
                case GetPowerSupplyComponentDto powerSupplyDto:
                {
                    //Create a subquery based on the Power Supply type
                    var powerSupplyQuery = query.OfType<PowerSupplyComponent>();
                        
                    //Filter by Power Supply Component class variables
                    powerSupplyQuery = powerSupplyQuery.Where(c =>
                        (powerSupplyDto.FormFactor == null || powerSupplyDto.FormFactor.Contains(c.FormFactor)) &&
                        (powerSupplyDto.EfficiencyRating == null || (c.EfficiencyRating != null && powerSupplyDto.EfficiencyRating.Contains(c.EfficiencyRating))) &&
                        (powerSupplyDto.ModularityType == null || powerSupplyDto.ModularityType.Contains(c.ModularityType)) &&
                        (powerSupplyDto.IsFanless == null || powerSupplyDto.IsFanless == c.IsFanless) &&
                        (powerSupplyDto.PowerOutputStart == null || powerSupplyDto.PowerOutputStart <= c.PowerOutput) &&
                        (powerSupplyDto.PowerOutputEnd == null || powerSupplyDto.PowerOutputEnd >= c.PowerOutput) &&
                        (powerSupplyDto.LengthStart == null || powerSupplyDto.LengthStart <= c.Length) &&
                        (powerSupplyDto.LengthEnd == null || powerSupplyDto.LengthEnd >= c.Length)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        powerSupplyQuery = powerSupplyQuery.Search(dto.Query, c => c.FormFactor, c => c.EfficiencyRating!, c => c.ModularityType);
                    }

                    query = powerSupplyQuery;

                    break;
                    }
                case GetStorageComponentDto storageDto:
                {
                    //Create a subquery based on the Storage type
                    var storageQuery = query.OfType<StorageComponent>();
                    
                    //Filter by Storage Component class variables
                    storageQuery = storageQuery.Where(c =>
                        (storageDto.Series == null || storageDto.Series.Contains(c.Series)) &&
                        (storageDto.DriveType == null || storageDto.DriveType.Contains(c.DriveType)) &&
                        (storageDto.FormFactor == null || storageDto.FormFactor.Contains(c.FormFactor)) &&
                        (storageDto.Interface == null || storageDto.Interface.Contains(c.Interface)) &&
                        (storageDto.HasNVMe == null || storageDto.HasNVMe == c.HasNVMe) &&
                        (storageDto.CapacityStart == null || storageDto.CapacityStart <= c.Capacity) &&
                        (storageDto.CapacityEnd == null || storageDto.CapacityEnd >= c.Capacity)
                    );

                    //Apply search for the Case Fan Component
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        storageQuery = storageQuery.Search(dto.Query, c => c.Series, c => c.DriveType, c => c.FormFactor, c => c.Interface);
                    }

                    query = storageQuery;

                    break;
                }
            };

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get components with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<BaseComponent> components = await query.ToListAsync();

            //Declare response variable
            List<BaseComponentResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Components";

                //Return an invalid response if try/catch statement catches a type assignment error
                try
                {
                    //Create a component response list
                    responses = [.. Linq.Enumerable.Select<BaseComponent, BaseComponentResponseDto>(components, component =>
                    {
                        return component switch
                        {
                            CaseComponent caseComponent => new CaseComponentResponseDto
                            {
                                Name = caseComponent.Name,
                                Manufacturer = caseComponent.Manufacturer,
                                Release = caseComponent.Release,
                                Type = caseComponent.Type,
                                FormFactor = caseComponent.FormFactor,
                                PowerSupplyShrouded = caseComponent.PowerSupplyShrouded,
                                PowerSupplyAmount = caseComponent.PowerSupplyAmount,
                                HasTransparentSidePanel = caseComponent.HasTransparentSidePanel,
                                SidePanelType = caseComponent.SidePanelType,
                                MaxVideoCardLength = caseComponent.MaxVideoCardLength,
                                MaxCPUCoolerHeight = caseComponent.MaxCPUCoolerHeight,
                                Internal35BayAmount = caseComponent.Internal35BayAmount,
                                Internal25BayAmount = caseComponent.Internal25BayAmount,
                                External35BayAmount = caseComponent.External35BayAmount,
                                External525BayAmount = caseComponent.External525BayAmount,
                                ExpansionSlotAmount = caseComponent.ExpansionSlotAmount,
                                Dimensions = caseComponent.Dimensions,
                                Weight = caseComponent.Weight,
                                SupportsRearConnectingMotherboard = caseComponent.SupportsRearConnectingMotherboard
                            },
                            CaseFanComponent caseFanComponent => new CaseFanComponentResponseDto
                            {
                                Name = caseFanComponent.Name,
                                Manufacturer = caseFanComponent.Manufacturer,
                                Release = caseFanComponent.Release,
                                Type = caseFanComponent.Type,
                                Size = caseFanComponent.Size,
                                Quantity = caseFanComponent.Quantity,
                                MinAirflow = caseFanComponent.MinAirflow,
                                MaxAirflow = caseFanComponent.MaxAirflow,
                                MinNoiseLevel = caseFanComponent.MinNoiseLevel,
                                MaxNoiseLevel = caseFanComponent.MaxNoiseLevel,
                                PulseWidthModulation = caseFanComponent.PulseWidthModulation,
                                LEDType = caseFanComponent.LEDType,
                                ConnectorType = caseFanComponent.ConnectorType,
                                ControllerType = caseFanComponent.ControllerType,
                                StaticPressureAmount = caseFanComponent.StaticPressureAmount,
                                FlowDirection = caseFanComponent.FlowDirection
                            },
                            CoolerComponent coolerComponent => new CoolerComponentResponseDto
                            {
                                Name = coolerComponent.Name,
                                Manufacturer = coolerComponent.Manufacturer,
                                Release = coolerComponent.Release,
                                Type = coolerComponent.Type,
                                MinFanRotationSpeed = coolerComponent.MinFanRotationSpeed,
                                MaxFanRotationSpeed = coolerComponent.MaxFanRotationSpeed,
                                MinNoiseLevel = coolerComponent.MinNoiseLevel,
                                MaxNoiseLevel = coolerComponent.MaxNoiseLevel,
                                Height = coolerComponent.Height,
                                IsWaterCooled = coolerComponent.IsWaterCooled,
                                RadiatorSize = coolerComponent.RadiatorSize,
                                CanOperateFanless = coolerComponent.CanOperateFanless,
                                FanSize = coolerComponent.FanSize,
                                FanQuantity = coolerComponent.FanQuantity
                            },
                            CPUComponent cpuComponent => new CPUComponentResponseDto
                            {
                                Name = cpuComponent.Name,
                                Manufacturer = cpuComponent.Manufacturer,
                                Release = cpuComponent.Release,
                                Type = cpuComponent.Type,
                                Series = cpuComponent.Series,
                                Microarchitecture = cpuComponent.Microarchitecture,
                                CoreFamily = cpuComponent.CoreFamily,
                                SocketType = cpuComponent.SocketType,
                                CoreTotal = cpuComponent.CoreTotal,
                                PerformanceAmount = cpuComponent.PerformanceAmount,
                                EfficiencyAmount = cpuComponent.EfficiencyAmount,
                                ThreadsAmount = cpuComponent.ThreadsAmount,
                                BasePerformanceSpeed = cpuComponent.BasePerformanceSpeed,
                                BoostPerformanceSpeed = cpuComponent.BoostPerformanceSpeed,
                                BaseEfficiencySpeed = cpuComponent.BaseEfficiencySpeed,
                                BoostEfficiencySpeed = cpuComponent.BoostEfficiencySpeed,
                                L1 = cpuComponent.L1,
                                L2 = cpuComponent.L2,
                                L3 = cpuComponent.L3,
                                L4 = cpuComponent.L4,
                                IncludesCooler = cpuComponent.IncludesCooler,
                                Lithography = cpuComponent.Lithography,
                                SupportsSimultaneousMultithreading = cpuComponent.SupportsSimultaneousMultithreading,
                                MemoryType = cpuComponent.MemoryType,
                                PackagingType = cpuComponent.PackagingType,
                                SupportsErrorCorrectingCode = cpuComponent.SupportsErrorCorrectingCode,
                                ThermalDesignPower = cpuComponent.ThermalDesignPower
                            },
                            GPUComponent gpuComponent => new GPUComponentResponseDto
                            {
                                Name = gpuComponent.Name,
                                Manufacturer = gpuComponent.Manufacturer,
                                Release = gpuComponent.Release,
                                Type = gpuComponent.Type,
                                Chipset = gpuComponent.Chipset,
                                VideoMemoryAmount = gpuComponent.VideoMemoryAmount,
                                VideoMemoryType = gpuComponent.VideoMemoryType,
                                CoreBaseClockSpeed = gpuComponent.CoreBaseClockSpeed,
                                CoreBoostClockSpeed = gpuComponent.CoreBoostClockSpeed,
                                CoreCount = gpuComponent.CoreCount,
                                EffectiveMemoryClockSpeed = gpuComponent.EffectiveMemoryClockSpeed,
                                MemoryBusWidth = gpuComponent.MemoryBusWidth,
                                FrameSync = gpuComponent.FrameSync,
                                Length = gpuComponent.Length,
                                ThermalDesignPower = gpuComponent.ThermalDesignPower,
                                CaseExpansionSlotWidth = gpuComponent.CaseExpansionSlotWidth,
                                TotalSlotWidth = gpuComponent.TotalSlotWidth,
                                CoolingType = gpuComponent.CoolingType
                            },
                            MemoryComponent memoryComponent => new MemoryComponentResponseDto
                            {
                                Name = memoryComponent.Name,
                                Manufacturer = memoryComponent.Manufacturer,
                                Release = memoryComponent.Release,
                                Type = memoryComponent.Type,
                                Speed = memoryComponent.Speed,
                                RAMType = memoryComponent.RAMType,
                                FormFactor = memoryComponent.FormFactor,
                                Capacity = memoryComponent.Capacity,
                                CASLatency = memoryComponent.CASLatency,
                                Timings = memoryComponent.Timings,
                                ModuleQuantity = memoryComponent.ModuleQuantity,
                                ModuleCapacity = memoryComponent.ModuleCapacity,
                                ErrorCorrectingCode = memoryComponent.ErrorCorrectingCode,
                                RegisteredType = memoryComponent.RegisteredType,
                                HaveHeatSpreader = memoryComponent.HaveHeatSpreader,
                                HaveRGB = memoryComponent.HaveRGB,
                                Height = memoryComponent.Height,
                                Voltage = memoryComponent.Voltage
                            },
                            MonitorComponent monitorComponent => new MonitorComponentResponseDto
                            {
                                Name = monitorComponent.Name,
                                Manufacturer = monitorComponent.Manufacturer,
                                Release = monitorComponent.Release,
                                Type = monitorComponent.Type,
                                ScreenSize = monitorComponent.ScreenSize,
                                HorizontalResolution = monitorComponent.HorizontalResolution,
                                VerticalResolution = monitorComponent.VerticalResolution,
                                MaxRefreshRate = monitorComponent.MaxRefreshRate,
                                PanelType = monitorComponent.PanelType,
                                ResponseTime = monitorComponent.ResponseTime,
                                ViewingAngle = monitorComponent.ViewingAngle,
                                AspectRatio = monitorComponent.AspectRatio,
                                MaxBrightness = monitorComponent.MaxBrightness,
                                HighDynamicRangeType = monitorComponent.HighDynamicRangeType,
                                AdaptiveSyncType = monitorComponent.AdaptiveSyncType
                            },
                            MotherboardComponent motherboardComponent => new MotherboardComponentResponseDto
                            {
                                Name = motherboardComponent.Name,
                                Manufacturer = motherboardComponent.Manufacturer,
                                Release = motherboardComponent.Release,
                                Type = motherboardComponent.Type,
                                SocketType = motherboardComponent.SocketType,
                                FormFactor = motherboardComponent.FormFactor,
                                ChipsetType = motherboardComponent.ChipsetType,
                                RAMType = motherboardComponent.RAMType,
                                RAMSlotsAmount = motherboardComponent.RAMSlotsAmount,
                                MaxRAMAmount = motherboardComponent.MaxRAMAmount,
                                SerialATAttachment6GBsAmount = motherboardComponent.SerialATAttachment6GBsAmount,
                                SerialATAttachment3GBsAmount = motherboardComponent.SerialATAttachment3GBsAmount,
                                U2PortAmount = motherboardComponent.U2PortAmount,
                                WirelessNetworkingStandard = motherboardComponent.WirelessNetworkingStandard,
                                CPUFanHeaderAmount = motherboardComponent.CPUFanHeaderAmount,
                                CaseFanHeaderAmount = motherboardComponent.CaseFanHeaderAmount,
                                PumpHeaderAmount = motherboardComponent.PumpHeaderAmount,
                                CPUOptionalFanHeaderAmount = motherboardComponent.CPUOptionalFanHeaderAmount,
                                ARGB5vHeaderAmount = motherboardComponent.ARGB5vHeaderAmount,
                                RGB12vHeaderAmount = motherboardComponent.RGB12vHeaderAmount,
                                HasPowerButtonHeader = motherboardComponent.HasPowerButtonHeader,
                                HasResetButtonHeader = motherboardComponent.HasResetButtonHeader,
                                HasPowerLEDHeader = motherboardComponent.HasPowerLEDHeader,
                                HasHDDLEDHeader = motherboardComponent.HasHDDLEDHeader,
                                TemperatureSensorHeaderAmount = motherboardComponent.TemperatureSensorHeaderAmount,
                                ThunderboltHeaderAmount = motherboardComponent.ThunderboltHeaderAmount,
                                COMPortHeaderAmount = motherboardComponent.COMPortHeaderAmount,
                                MainPowerType = motherboardComponent.MainPowerType,
                                HasECCSupport = motherboardComponent.HasECCSupport,
                                HasRAIDSupport = motherboardComponent.HasRAIDSupport,
                                HasFlashback = motherboardComponent.HasFlashback,
                                HasCMOS = motherboardComponent.HasCMOS,
                                AudioChipset = motherboardComponent.AudioChipset,
                                MaxAudioChannels = motherboardComponent.MaxAudioChannels
                            },
                            PowerSupplyComponent powerSupplyComponent => new PowerSupplyComponentResponseDto
                            {
                                Name = powerSupplyComponent.Name,
                                Manufacturer = powerSupplyComponent.Manufacturer,
                                Release = powerSupplyComponent.Release,
                                Type = powerSupplyComponent.Type,
                                PowerOutput = powerSupplyComponent.PowerOutput,
                                FormFactor = powerSupplyComponent.FormFactor,
                                EfficiencyRating = powerSupplyComponent.EfficiencyRating,
                                ModularityType = powerSupplyComponent.ModularityType,
                                Length = powerSupplyComponent.Length,
                                IsFanless = powerSupplyComponent.IsFanless
                            },
                            StorageComponent storageComponent => new StorageComponentResponseDto
                            {
                                Name = storageComponent.Name,
                                Manufacturer = storageComponent.Manufacturer,
                                Release = storageComponent.Release,
                                Type = storageComponent.Type,
                                Series = storageComponent.Series,
                                Capacity = storageComponent.Capacity,
                                DriveType = storageComponent.DriveType,
                                FormFactor = storageComponent.FormFactor,
                                Interface = storageComponent.Interface,
                                HasNVMe = storageComponent.HasNVMe
                            },
                            _ => throw new NotImplementedException("Invalid Component Type"),
                        };
                    })];
                }
                catch (Exception ex)
                {
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "PUT",
                        "Component",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        $"Operation Failed - {ex}"
                    );

                    //Return not found response
                    return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid Component Type!", detail = ex.Message });
                }
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Components";

                //Return an invalid response if try/catch statement catches a type assignment error
                try
                {
                    //Create a component response list
                    responses = [.. Linq.Enumerable.Select<BaseComponent, BaseComponentResponseDto>(components, component =>
                    {
                        return component switch
                        {
                            CaseComponent caseComponent => new CaseComponentResponseDto
                            {
                                Name = caseComponent.Name,
                                Manufacturer = caseComponent.Manufacturer,
                                Release = caseComponent.Release,
                                Type = caseComponent.Type,
                                FormFactor = caseComponent.FormFactor,
                                PowerSupplyShrouded = caseComponent.PowerSupplyShrouded,
                                PowerSupplyAmount = caseComponent.PowerSupplyAmount,
                                HasTransparentSidePanel = caseComponent.HasTransparentSidePanel,
                                SidePanelType = caseComponent.SidePanelType,
                                MaxVideoCardLength = caseComponent.MaxVideoCardLength,
                                MaxCPUCoolerHeight = caseComponent.MaxCPUCoolerHeight,
                                Internal35BayAmount = caseComponent.Internal35BayAmount,
                                Internal25BayAmount = caseComponent.Internal25BayAmount,
                                External35BayAmount = caseComponent.External35BayAmount,
                                External525BayAmount = caseComponent.External525BayAmount,
                                ExpansionSlotAmount = caseComponent.ExpansionSlotAmount,
                                Dimensions = caseComponent.Dimensions,
                                Weight = caseComponent.Weight,
                                SupportsRearConnectingMotherboard = caseComponent.SupportsRearConnectingMotherboard,
                                DatabaseEntryAt = caseComponent.DatabaseEntryAt,
                                LastEditedAt = caseComponent.LastEditedAt,
                                Note = caseComponent.Note
                            },
                            CaseFanComponent caseFanComponent => new CaseFanComponentResponseDto
                            {
                                Name = caseFanComponent.Name,
                                Manufacturer = caseFanComponent.Manufacturer,
                                Release = caseFanComponent.Release,
                                Type = caseFanComponent.Type,
                                Size = caseFanComponent.Size,
                                Quantity = caseFanComponent.Quantity,
                                MinAirflow = caseFanComponent.MinAirflow,
                                MaxAirflow = caseFanComponent.MaxAirflow,
                                MinNoiseLevel = caseFanComponent.MinNoiseLevel,
                                MaxNoiseLevel = caseFanComponent.MaxNoiseLevel,
                                PulseWidthModulation = caseFanComponent.PulseWidthModulation,
                                LEDType = caseFanComponent.LEDType,
                                ConnectorType = caseFanComponent.ConnectorType,
                                ControllerType = caseFanComponent.ControllerType,
                                StaticPressureAmount = caseFanComponent.StaticPressureAmount,
                                FlowDirection = caseFanComponent.FlowDirection,
                                DatabaseEntryAt = caseFanComponent.DatabaseEntryAt,
                                LastEditedAt = caseFanComponent.LastEditedAt,
                                Note = caseFanComponent.Note
                            },
                            CoolerComponent coolerComponent => new CoolerComponentResponseDto
                            {
                                Name = coolerComponent.Name,
                                Manufacturer = coolerComponent.Manufacturer,
                                Release = coolerComponent.Release,
                                Type = coolerComponent.Type,
                                MinFanRotationSpeed = coolerComponent.MinFanRotationSpeed,
                                MaxFanRotationSpeed = coolerComponent.MaxFanRotationSpeed,
                                MinNoiseLevel = coolerComponent.MinNoiseLevel,
                                MaxNoiseLevel = coolerComponent.MaxNoiseLevel,
                                Height = coolerComponent.Height,
                                IsWaterCooled = coolerComponent.IsWaterCooled,
                                RadiatorSize = coolerComponent.RadiatorSize,
                                CanOperateFanless = coolerComponent.CanOperateFanless,
                                FanSize = coolerComponent.FanSize,
                                FanQuantity = coolerComponent.FanQuantity,
                                DatabaseEntryAt = coolerComponent.DatabaseEntryAt,
                                LastEditedAt = coolerComponent.LastEditedAt,
                                Note = coolerComponent.Note
                            },
                            CPUComponent cpuComponent => new CPUComponentResponseDto
                            {
                                Name = cpuComponent.Name,
                                Manufacturer = cpuComponent.Manufacturer,
                                Release = cpuComponent.Release,
                                Type = cpuComponent.Type,
                                Series = cpuComponent.Series,
                                Microarchitecture = cpuComponent.Microarchitecture,
                                CoreFamily = cpuComponent.CoreFamily,
                                SocketType = cpuComponent.SocketType,
                                CoreTotal = cpuComponent.CoreTotal,
                                PerformanceAmount = cpuComponent.PerformanceAmount,
                                EfficiencyAmount = cpuComponent.EfficiencyAmount,
                                ThreadsAmount = cpuComponent.ThreadsAmount,
                                BasePerformanceSpeed = cpuComponent.BasePerformanceSpeed,
                                BoostPerformanceSpeed = cpuComponent.BoostPerformanceSpeed,
                                BaseEfficiencySpeed = cpuComponent.BaseEfficiencySpeed,
                                BoostEfficiencySpeed = cpuComponent.BoostEfficiencySpeed,
                                L1 = cpuComponent.L1,
                                L2 = cpuComponent.L2,
                                L3 = cpuComponent.L3,
                                L4 = cpuComponent.L4,
                                IncludesCooler = cpuComponent.IncludesCooler,
                                Lithography = cpuComponent.Lithography,
                                SupportsSimultaneousMultithreading = cpuComponent.SupportsSimultaneousMultithreading,
                                MemoryType = cpuComponent.MemoryType,
                                PackagingType = cpuComponent.PackagingType,
                                SupportsErrorCorrectingCode = cpuComponent.SupportsErrorCorrectingCode,
                                ThermalDesignPower = cpuComponent.ThermalDesignPower,
                                DatabaseEntryAt = cpuComponent.DatabaseEntryAt,
                                LastEditedAt = cpuComponent.LastEditedAt,
                                Note = cpuComponent.Note
                            },
                            GPUComponent gpuComponent => new GPUComponentResponseDto
                            {
                                Name = gpuComponent.Name,
                                Manufacturer = gpuComponent.Manufacturer,
                                Release = gpuComponent.Release,
                                Type = gpuComponent.Type,
                                Chipset = gpuComponent.Chipset,
                                VideoMemoryAmount = gpuComponent.VideoMemoryAmount,
                                VideoMemoryType = gpuComponent.VideoMemoryType,
                                CoreBaseClockSpeed = gpuComponent.CoreBaseClockSpeed,
                                CoreBoostClockSpeed = gpuComponent.CoreBoostClockSpeed,
                                CoreCount = gpuComponent.CoreCount,
                                EffectiveMemoryClockSpeed = gpuComponent.EffectiveMemoryClockSpeed,
                                MemoryBusWidth = gpuComponent.MemoryBusWidth,
                                FrameSync = gpuComponent.FrameSync,
                                Length = gpuComponent.Length,
                                ThermalDesignPower = gpuComponent.ThermalDesignPower,
                                CaseExpansionSlotWidth = gpuComponent.CaseExpansionSlotWidth,
                                TotalSlotWidth = gpuComponent.TotalSlotWidth,
                                CoolingType = gpuComponent.CoolingType,
                                DatabaseEntryAt = gpuComponent.DatabaseEntryAt,
                                LastEditedAt = gpuComponent.LastEditedAt,
                                Note = gpuComponent.Note
                            },
                            MemoryComponent memoryComponent => new MemoryComponentResponseDto
                            {
                                Name = memoryComponent.Name,
                                Manufacturer = memoryComponent.Manufacturer,
                                Release = memoryComponent.Release,
                                Type = memoryComponent.Type,
                                Speed = memoryComponent.Speed,
                                RAMType = memoryComponent.RAMType,
                                FormFactor = memoryComponent.FormFactor,
                                Capacity = memoryComponent.Capacity,
                                CASLatency = memoryComponent.CASLatency,
                                Timings = memoryComponent.Timings,
                                ModuleQuantity = memoryComponent.ModuleQuantity,
                                ModuleCapacity = memoryComponent.ModuleCapacity,
                                ErrorCorrectingCode = memoryComponent.ErrorCorrectingCode,
                                RegisteredType = memoryComponent.RegisteredType,
                                HaveHeatSpreader = memoryComponent.HaveHeatSpreader,
                                HaveRGB = memoryComponent.HaveRGB,
                                Height = memoryComponent.Height,
                                Voltage = memoryComponent.Voltage,
                                DatabaseEntryAt = memoryComponent.DatabaseEntryAt,
                                LastEditedAt = memoryComponent.LastEditedAt,
                                Note = memoryComponent.Note
                            },
                            MonitorComponent monitorComponent => new MonitorComponentResponseDto
                            {
                                Name = monitorComponent.Name,
                                Manufacturer = monitorComponent.Manufacturer,
                                Release = monitorComponent.Release,
                                Type = monitorComponent.Type,
                                ScreenSize = monitorComponent.ScreenSize,
                                HorizontalResolution = monitorComponent.HorizontalResolution,
                                VerticalResolution = monitorComponent.VerticalResolution,
                                MaxRefreshRate = monitorComponent.MaxRefreshRate,
                                PanelType = monitorComponent.PanelType,
                                ResponseTime = monitorComponent.ResponseTime,
                                ViewingAngle = monitorComponent.ViewingAngle,
                                AspectRatio = monitorComponent.AspectRatio,
                                MaxBrightness = monitorComponent.MaxBrightness,
                                HighDynamicRangeType = monitorComponent.HighDynamicRangeType,
                                AdaptiveSyncType = monitorComponent.AdaptiveSyncType,
                                DatabaseEntryAt = monitorComponent.DatabaseEntryAt,
                                LastEditedAt = monitorComponent.LastEditedAt,
                                Note = monitorComponent.Note
                            },
                            MotherboardComponent motherboardComponent => new MotherboardComponentResponseDto
                            {
                                Name = motherboardComponent.Name,
                                Manufacturer = motherboardComponent.Manufacturer,
                                Release = motherboardComponent.Release,
                                Type = motherboardComponent.Type,
                                SocketType = motherboardComponent.SocketType,
                                FormFactor = motherboardComponent.FormFactor,
                                ChipsetType = motherboardComponent.ChipsetType,
                                RAMType = motherboardComponent.RAMType,
                                RAMSlotsAmount = motherboardComponent.RAMSlotsAmount,
                                MaxRAMAmount = motherboardComponent.MaxRAMAmount,
                                SerialATAttachment6GBsAmount = motherboardComponent.SerialATAttachment6GBsAmount,
                                SerialATAttachment3GBsAmount = motherboardComponent.SerialATAttachment3GBsAmount,
                                U2PortAmount = motherboardComponent.U2PortAmount,
                                WirelessNetworkingStandard = motherboardComponent.WirelessNetworkingStandard,
                                CPUFanHeaderAmount = motherboardComponent.CPUFanHeaderAmount,
                                CaseFanHeaderAmount = motherboardComponent.CaseFanHeaderAmount,
                                PumpHeaderAmount = motherboardComponent.PumpHeaderAmount,
                                CPUOptionalFanHeaderAmount = motherboardComponent.CPUOptionalFanHeaderAmount,
                                ARGB5vHeaderAmount = motherboardComponent.ARGB5vHeaderAmount,
                                RGB12vHeaderAmount = motherboardComponent.RGB12vHeaderAmount,
                                HasPowerButtonHeader = motherboardComponent.HasPowerButtonHeader,
                                HasResetButtonHeader = motherboardComponent.HasResetButtonHeader,
                                HasPowerLEDHeader = motherboardComponent.HasPowerLEDHeader,
                                HasHDDLEDHeader = motherboardComponent.HasHDDLEDHeader,
                                TemperatureSensorHeaderAmount = motherboardComponent.TemperatureSensorHeaderAmount,
                                ThunderboltHeaderAmount = motherboardComponent.ThunderboltHeaderAmount,
                                COMPortHeaderAmount = motherboardComponent.COMPortHeaderAmount,
                                MainPowerType = motherboardComponent.MainPowerType,
                                HasECCSupport = motherboardComponent.HasECCSupport,
                                HasRAIDSupport = motherboardComponent.HasRAIDSupport,
                                HasFlashback = motherboardComponent.HasFlashback,
                                HasCMOS = motherboardComponent.HasCMOS,
                                AudioChipset = motherboardComponent.AudioChipset,
                                MaxAudioChannels = motherboardComponent.MaxAudioChannels,
                                DatabaseEntryAt = motherboardComponent.DatabaseEntryAt,
                                LastEditedAt = motherboardComponent.LastEditedAt,
                                Note = motherboardComponent.Note
                            },
                            PowerSupplyComponent powerSupplyComponent => new PowerSupplyComponentResponseDto
                            {
                                Name = powerSupplyComponent.Name,
                                Manufacturer = powerSupplyComponent.Manufacturer,
                                Release = powerSupplyComponent.Release,
                                Type = powerSupplyComponent.Type,
                                PowerOutput = powerSupplyComponent.PowerOutput,
                                FormFactor = powerSupplyComponent.FormFactor,
                                EfficiencyRating = powerSupplyComponent.EfficiencyRating,
                                ModularityType = powerSupplyComponent.ModularityType,
                                Length = powerSupplyComponent.Length,
                                IsFanless = powerSupplyComponent.IsFanless,
                                DatabaseEntryAt = powerSupplyComponent.DatabaseEntryAt,
                                LastEditedAt = powerSupplyComponent.LastEditedAt,
                                Note = powerSupplyComponent.Note
                            },
                            StorageComponent storageComponent => new StorageComponentResponseDto
                            {
                                Name = storageComponent.Name,
                                Manufacturer = storageComponent.Manufacturer,
                                Release = storageComponent.Release,
                                Type = storageComponent.Type,
                                Series = storageComponent.Series,
                                Capacity = storageComponent.Capacity,
                                DriveType = storageComponent.DriveType,
                                FormFactor = storageComponent.FormFactor,
                                Interface = storageComponent.Interface,
                                HasNVMe = storageComponent.HasNVMe,
                                DatabaseEntryAt = storageComponent.DatabaseEntryAt,
                                LastEditedAt = storageComponent.LastEditedAt,
                                Note = storageComponent.Note
                            },
                            _ => throw new NotImplementedException("Invalid Component Type"),
                        };
                    })];
                }
                catch (Exception ex)
                {
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "PUT",
                        "Component",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        $"Operation Failed - {ex}"
                    );

                    //Return not found response
                    return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid Component Type!", detail = ex.Message });
                }

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Component",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("component.gotComponents", new
            {
                componentIds = components.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the components
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Component for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponent(Guid id)
        {
            //Get component id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the component to delete
            var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == id);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Component",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Component"
                );

                //Return not found response
                return NotFound(new { component = "Component not found!" });
            }

            //Delete the component
            _db.Components.Remove(component);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Component",
                ip,
                component.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("component.deleted", new
            {
                componentId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { component = "Component deleted successfully!" });
        }
    }
}
