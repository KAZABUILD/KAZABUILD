using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class UpdateMotherboardComponentDto : UpdateBaseComponentDto
    {
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string? SocketType { get; set; }

        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string? ChipsetType { get; set; }

        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string? RAMType { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 1 and 15")]
        public int? RAMSlotsAmount { get; set; }

        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmount { get; set; } = default!;

        [Range(0, 20, ErrorMessage = "Sata6Gbs Amount must be between 0 and 20")]
        public int? Sata6GbsAmount { get; set; } = default!;

        [Range(0, 20, ErrorMessage = "Sata3Gbs Amount must be between 0 and 20")]
        public int? Sata3GbsAmount { get; set; } = default!;

        [Range(0, 20, ErrorMessage = "U2 Amount must be between 0 and 20")]
        public int? U2Amount { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Wireless Networking Type cannot be longer than 50 characters!")]
        public string? WirelessNetworkingType { get; set; } = default!;

        [Range(0, 20, ErrorMessage = "Cpu Fan Amount must be between 0 and 20")]
        public int? CpuFanAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Amount must be between 0 and 20")]
        public int? CaseFanAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Cpu Opt Fan Header Amount must be between 0 and 20")]
        public int? CpuOptFanHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "CpuOptFan Amount must be between 0 and 20")]
        public int? ARGB5vAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Rgb12v Amount must be between 0 and 20")]
        public int? RGB12vAmount { get; set; }

        public bool? HasPowerButton { get; set; }

        public bool? HasResetButton { get; set; }

        public bool? HasPowerLED { get; set; }

        public bool? HasHDDLED { get; set; }

        [Range(0, 20, ErrorMessage = "Temprature Sensor Amount must be between 0 and 20")]
        public int? TempratureSensorAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Amount must be between 0 and 20")]
        public int? ThunderboltAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Amount must be between 0 and 20")]
        public int? ComPortAmount { get; set; }

        [StringLength(50, ErrorMessage = "Main power type cannot be longer than 50 characters!")]
        public string? MainPower { get; set; }

        public bool? HasEccSupport { get; set; } = default!;

        public bool? HasRaidSupport { get; set; } = default!;

        public bool? HasFlashback { get; set; } = default!;

        public bool? HasClearCmos { get; set; } = default!;

        [StringLength(50, ErrorMessage = "Audio Chipset must be between 0 and 20!")]
        public string? AudioChipset { get; set; } = default!;

        [Range(1, 32, ErrorMessage = "Channels type cannot be longer than 50 characters!")]
        public decimal? AudioChannelsAmount { get; set; } = default!;
    }
}
