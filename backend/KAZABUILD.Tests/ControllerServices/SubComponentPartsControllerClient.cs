using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.SubComponentPart;

namespace KAZABUILD.Tests.ControllerServices;

public class SubComponentPartsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddSubComponentPart(CreateSubComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/SubComponentParts/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateSubComponentPart(String subComponentPartId, UpdateSubComponentPartDto dto)
    {
        return await _client.PutAsJsonAsync("/SubComponentParts/"+subComponentPartId, dto);
    }

    public async Task<HttpResponseMessage> DeleteSubComponentPart(String subComponentPartId)
    {
        return await _client.DeleteAsync("/SubComponentParts/"+subComponentPartId);
    }

    public async Task<HttpResponseMessage> GetSubComponentParts(GetSubComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/SubComponentParts/get", dto);
    }

    public async Task<HttpResponseMessage> GetSubComponentPart(String subComponentPartId)
    {
        return await _client.GetAsync("/SubComponentParts/"+subComponentPartId);
    }
}
