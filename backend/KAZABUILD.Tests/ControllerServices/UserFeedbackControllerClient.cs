using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserFeedback;

namespace KAZABUILD.Tests.ControllerServices;

public class UserFeedbackControllerClient(HttpClient _client): BaseApiControllerService
{
    public async Task<HttpResponseMessage> AddUserFeedback(CreateUserFeedbackDto dto)
    {
        return await _client.PostAsJsonAsync("/UserFeedback/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserFeedback(String userFeedbackId, UpdateUserFeedbackDto dto)
    {
        return await _client.PutAsJsonAsync("/UserFeedback/" + userFeedbackId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserFeedback(String userFeedbackId)
    {
        return await _client.DeleteAsync("/UserFeedback/" + userFeedbackId);
    }

    public async Task<HttpResponseMessage> GetUserFeedbacks(GetUserFeedbackDto dto)
    {
        return await _client.PostAsJsonAsync("/UserFeedback/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserFeedback(String userFeedbackId)
    {
        return await _client.GetAsync("/UserFeedback/" + userFeedbackId);
    }
}
