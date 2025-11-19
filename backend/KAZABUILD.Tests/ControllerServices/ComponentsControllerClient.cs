using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponent(CreateBaseComponentDto dto)
    {
        return await _client.PostAsJsonAsync("/Components/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponent(String componentId, UpdateBaseComponentDto dto)
    {
        return await _client.PutAsJsonAsync("/Components/"+componentId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponent(String componentId)
    {
        return await _client.DeleteAsync("/Components/"+componentId);
    }

    public async Task<HttpResponseMessage> GetComponents(GetBaseComponentDto dto)
    {
        return await _client.PostAsJsonAsync("/Components/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponent(String componentId)
    {
        return await _client.GetAsync("/Components/"+componentId);
    }
}
