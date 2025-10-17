using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentPart;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentPartsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponentPart(CreateComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentParts/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentPart(String componentPartId, UpdateComponentPartDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentParts/"+componentPartId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentPart(String componentPartId)
    {
        return await _client.DeleteAsync("/ComponentParts/"+componentPartId);
    }

    public async Task<HttpResponseMessage> GetComponentParts(GetComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentParts/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentPart(String componentPartId)
    {
        return await _client.GetAsync("/ComponentParts/"+componentPartId);
    }
}
