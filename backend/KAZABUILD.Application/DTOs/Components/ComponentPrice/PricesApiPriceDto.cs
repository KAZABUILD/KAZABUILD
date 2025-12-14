using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class PricesApiPriceDto
    {
        [JsonPropertyName("name")]
        public string Name { get; set; } = default!;

        [JsonPropertyName("type")]
        public string Type { get; set; } = default!;

        [JsonPropertyName("currency")]
        public string Currency { get; set; } = "PLN";
    }
}
