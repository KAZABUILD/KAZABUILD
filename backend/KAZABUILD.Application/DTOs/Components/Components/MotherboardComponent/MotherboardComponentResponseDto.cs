using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class MotherboardComponentResponseDto : BaseComponentResponseDto
    {
        public string? SocketType { get; set; }

        public string? FormFactor { get; set; }

        public string? ChipsetType { get; set; }

        public string? RAMType { get; set; }

        public int? RAMSlotsAmount { get; set; }

        public int? MaxRAMAmount { get; set; }

        public int? Sata6GbsAmount { get; set; }

        public int? Sata3GbsAmount { get; set; }

        public int? U2Amount { get; set; }

        public string? WirelessNetworkingType { get; set; }

        public int? CpuFanAmount { get; set; }

        public int? CaseFanAmount { get; set; }

        public int? PumpHeaderAmount { get; set; }

        public int? CpuOptFanHeaderAmount { get; set; }

        public int? ARGB5vAmount { get; set; }

        public int? RGB12vAmount { get; set; }

        public bool? HasPowerButton { get; set; }

        public bool? HasResetButton { get; set; }

        public bool? HasPowerLED { get; set; }

        public bool? HasHDDLED { get; set; }

        public int? TempratureSensorAmount { get; set; }

        public int? ThunderboltAmount { get; set; }

        public int? ComPortAmount { get; set; }

        public string? MainPower { get; set; }

        public bool? HasEccSupport { get; set; }

        public bool? HasRaidSupport { get; set; }

        public bool? HasFlashback { get; set; }

        public bool? HasClearCmos { get; set; }

        public string? AudioChipset { get; set; }

        public decimal? AudioChannelsAmount { get; set; }
    }
}
