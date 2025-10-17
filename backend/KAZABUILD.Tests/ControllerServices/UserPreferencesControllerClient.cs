using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserPreference;

namespace KAZABUILD.Tests.ControllerServices;

public class UserPreferencesControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddUserPreference(CreateUserPreferenceDto dto)
    {
        return await _client.PostAsJsonAsync("/UserPreferences/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserPreference(String userPreferenceId, UpdateUserPreferenceDto dto)
    {
        return await _client.PutAsJsonAsync("/UserPreferences/"+userPreferenceId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserPreference(String userPreferenceId)
    {
        return await _client.DeleteAsync("/UserPreferences/"+userPreferenceId);
    }

    public async Task<HttpResponseMessage> GetUserPreferences(GetUserPreferenceDto dto)
    {
        return await _client.PostAsJsonAsync("/UserPreferences/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserPreference(String UserPreferenceId)
    {
        return await _client.GetAsync("/UserPreferences/"+UserPreferenceId);
    }
}
