using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.Tag;

namespace KAZABUILD.Tests.ControllerServices;

public class TagsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddTag(CreateTagDto dto)
    {
        return await _client.PostAsJsonAsync("/Tags/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateTag(String tagId, UpdateTagDto dto)
    {
        return await _client.PutAsJsonAsync("/Tags/"+tagId, dto);
    }

    public async Task<HttpResponseMessage> DeleteTag(String tagId)
    {
        return await _client.DeleteAsync("/Tags/"+tagId);
    }

    public async Task<HttpResponseMessage> GetTags(GetTagDto dto)
    {
        return await _client.PostAsJsonAsync("/Tags/get", dto);
    }

    public async Task<HttpResponseMessage> GetTag(String tagId)
    {
        return await _client.GetAsync("/Tags/"+tagId);
    }
}
