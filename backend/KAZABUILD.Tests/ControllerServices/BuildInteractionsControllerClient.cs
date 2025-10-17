using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.BuildInteraction;

namespace KAZABUILD.Tests.ControllerServices;

public class BuildInteractionsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddBuildInteraction(CreateBuildInteractionDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildInteractions/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateBuildInteraction(String buildInteractionId, UpdateBuildInteractionDto dto)
    {
        return await _client.PutAsJsonAsync("/BuildInteractions/"+buildInteractionId, dto);
    }

    public async Task<HttpResponseMessage> DeleteBuildInteraction(String buildInteractionId)
    {
        return await _client.DeleteAsync("/BuildInteractions/"+buildInteractionId);
    }

    public async Task<HttpResponseMessage> GetBuildInteractions(GetBuildInteractionDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildInteractions/get", dto);
    }

    public async Task<HttpResponseMessage> GetBuildInteraction(String buildInteractionId)
    {
        return await _client.GetAsync("/BuildInteractions/"+buildInteractionId);
    }
}
