using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentPrice;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentPricesControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponentPrice(CreateComponentPriceDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentPrices/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentPrice(String componentPriceId, UpdateComponentPriceDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentPrices/"+componentPriceId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentPrice(String componentPriceId)
    {
        return await _client.DeleteAsync("/ComponentPrices/"+componentPriceId);
    }

    public async Task<HttpResponseMessage> GetComponentPrices(GetComponentPriceDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentPrices/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentPrice(String componentPriceId)
    {
        return await _client.GetAsync("/ComponentPrices/"+componentPriceId);
    }
}
