using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class GetMotherboardComponentDto : GetBaseComponentDto
    {
        public List<string>? SocketType { get; set; }

        public List<string>? FormFactor { get; set; }

        public List<string>? ChipsetType { get; set; }

        public List<string>? RAMType { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public int? RAMSlotsAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public int? RAMSlotsAmountEnd { get; set; }

        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmountStart { get; set; } 

        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmountEnd { get; set; } 

        [Range(0, 20, ErrorMessage = "Sata6Gbs Amount must be between 0 and 20")]
        public int? Sata6GbsAmountStart { get; set; } 

        [Range(0, 20, ErrorMessage = "Sata6Gbs Amount must be between 0 and 20")]
        public int? Sata6GbsAmountEnd { get; set; } 

        [Range(0, 20, ErrorMessage = "Sata3Gbs Amount must be between 0 and 20")]
        public int? Sata3GbsAmountStart { get; set; } 

        [Range(0, 20, ErrorMessage = "Sata3Gbs Amount must be between 0 and 20")]
        public int? Sata3GbsAmountEnd { get; set; } 

        [Range(0, 20, ErrorMessage = "U2 Amount must be between 0 and 20")]
        public int? U2AmountStart { get; set; } 

        [Range(0, 20, ErrorMessage = "U2 Amount must be between 0 and 20")]
        public int? U2AmountEnd { get; set; } 

        public List<string>? WirelessNetworkingType { get; set; }

        [Range(0, 20, ErrorMessage = "Cpu Fan Amount must be between 0 and 20")]
        public int? CpuFanAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Cpu Fan Amount must be between 0 and 20")]
        public int? CpuFanAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Amount must be between 0 and 20")]
        public int? CaseFanAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Amount must be between 0 and 20")]
        public int? CaseFanAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Cpu Opt Fan Header Amount must be between 0 and 20")]
        public int? CpuOptFanHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Cpu Opt Fan Header Amount must be between 0 and 20")]
        public int? CpuOptFanHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "CpuOptFan Amount must be between 0 and 20")]
        public int? ARGB5vAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "CpuOptFan Amount must be between 0 and 20")]
        public int? ARGB5vAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Rgb12v Amount must be between 0 and 20")]
        public int? RGB12vAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Rgb12v Amount must be between 0 and 20")]
        public int? RGB12vAmountEnd { get; set; }

        public bool? HasPowerButton { get; set; }

        public bool? HasResetButton { get; set; }

        public bool? HasPowerLED { get; set; }

        public bool? HasHDDLED { get; set; }

        [Range(0, 20, ErrorMessage = "Temperature Sensor Amount must be between 0 and 20")]
        public int? TemperatureSensorAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Temperature Sensor Amount must be between 0 and 20")]
        public int? TemperatureSensorAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Amount must be between 0 and 20")]
        public int? ThunderboltAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Amount must be between 0 and 20")]
        public int? ThunderboltAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Amount must be between 0 and 20")]
        public int? ComPortAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Amount must be between 0 and 20")]
        public int? ComPortAmountEnd { get; set; }

        [StringLength(50, ErrorMessage = "Main power type cannot be longer than 50 characters!")]
        public string? MainPowerStart { get; set; }

        [StringLength(50, ErrorMessage = "Main power type cannot be longer than 50 characters!")]
        public string? MainPowerEnd { get; set; }

        public bool? HasEccSupport { get; set; } 

        public bool? HasRaidSupport { get; set; } 

        public bool? HasFlashback { get; set; } 

        public bool? HasClearCmos { get; set; } 

        public List<string>? AudioChipset { get; set; }

        [Range(1, 32, ErrorMessage = "Channels type cannot be longer than 50 characters!")]
        public decimal AudioChannelsAmount { get; set; }
    }
}
