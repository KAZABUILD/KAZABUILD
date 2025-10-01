using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent
{
    public class GetCoolerSocketSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? SocketType { get; set; }
    }
}
