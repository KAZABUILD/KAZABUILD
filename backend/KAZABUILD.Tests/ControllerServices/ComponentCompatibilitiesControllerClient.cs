using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentCompatibility;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentCompatibilitiesControllerClient(HttpClient _client): BaseApiControllerService
{
    public async Task<HttpResponseMessage> AddComponentCompatibility(CreateComponentCompatibilityDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentCompatibilities/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentCompatibility(String componentCompabilityId, UpdateComponentCompatibilityDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentCompatibilities/"+componentCompabilityId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentCompatibility(String componentCompabilityId)
    {
        return await _client.DeleteAsync("/ComponentCompatibilities/"+componentCompabilityId);
    }

    public async Task<HttpResponseMessage> GetComponentCompatibilities(GetComponentCompatibilityDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentCompatibilities/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentCompatibility(String componentCompatibilityId)
    {
        return await _client.GetAsync("/ComponentCompatibilities/"+componentCompatibilityId);
    }
}
