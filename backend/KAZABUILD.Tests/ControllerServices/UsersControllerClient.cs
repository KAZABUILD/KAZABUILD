using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.User;

namespace KAZABUILD.Tests.ControllerServices;

public class UsersControllerClient
{
    private HttpClient _client;

    public UsersControllerClient(HttpClient client)
    {
        _client = client;
    }

    public async Task<HttpResponseMessage> addUser(CreateUserDto dto)
    {
        return await _client.PostAsJsonAsync("/Users/add", dto);
    }

    public async Task<HttpResponseMessage> updateUser(String userId, UpdateUserDto dto)
    {
        return await _client.PutAsJsonAsync("/Users/"+userId, dto);
    }

    public async Task<HttpResponseMessage> getUser(String userId)
    {
        return await _client.GetAsync("/Users/"+userId);
    }

    public async Task<HttpResponseMessage> deleteUser(String userId)
    {
        return await _client.DeleteAsync("/Users/"+userId);
    }

    public async Task<HttpResponseMessage> changePassword(String userId, ChangePasswordDto dto)
    {
        return await _client.PutAsJsonAsync("/Users/"+userId+"/change-password", dto);
    }

    public async Task<HttpResponseMessage> getUsers(UpdateUserDto dto)
    {
        return await _client.PutAsJsonAsync("/Users/get", dto);
    }



}
