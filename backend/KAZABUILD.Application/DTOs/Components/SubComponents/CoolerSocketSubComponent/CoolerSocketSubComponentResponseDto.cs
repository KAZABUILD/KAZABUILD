using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent
{
    public class CoolerSocketSubComponentResponseDto : BaseSubComponentResponseDto
    {
        public string? SocketType { get; set; }
    }
}
