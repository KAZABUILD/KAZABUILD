using System.Text.Json.Serialization;

namespace KAZABUILD.Application.DTOs.Components.ComponentPrice
{
    public class PricesApiPriceResponseDto
    {
        [JsonPropertyName("price")]
        public decimal Price { get; set; }

        [JsonPropertyName("currency")]
        public string Currency { get; set; } = "PLN";

        [JsonPropertyName("imageUrl")]
        public string? ImageUrl { get; set; }

        [JsonPropertyName("status")]
        public int Status { get; set; }
    }
}
