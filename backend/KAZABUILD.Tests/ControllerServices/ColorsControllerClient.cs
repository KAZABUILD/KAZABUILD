using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.Color;

namespace KAZABUILD.Tests.ControllerServices;

public class ColorsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddColor(CreateColorDto dto)
    {
        return await _client.PostAsJsonAsync("/Colors/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateColor(String colorId, UpdateColorDto dto)
    {
        return await _client.PutAsJsonAsync("/Colors/"+colorId, dto);
    }

    public async Task<HttpResponseMessage> DeleteColor(String colorId)
    {
        return await _client.DeleteAsync("/Colors/"+colorId);
    }

    public async Task<HttpResponseMessage> GetColors(GetColorDto dto)
    {
        return await _client.PostAsJsonAsync("/Colors/get", dto);
    }

    public async Task<HttpResponseMessage> GetColor(String colorId)
    {
        return await _client.GetAsync("/Colors/"+colorId);
    }
}
