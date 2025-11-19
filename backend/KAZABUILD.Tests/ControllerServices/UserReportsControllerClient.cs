using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserReport;

namespace KAZABUILD.Tests.ControllerServices;

public class UserReportsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddUserReport(CreateUserReportDto dto)
    {
        return await _client.PostAsJsonAsync("/UserReports/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserReport(String userReportId, UpdateUserReportDto dto)
    {
        return await _client.PutAsJsonAsync("/UserReports/" + userReportId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserReport(String userReportId)
    {
        return await _client.DeleteAsync("/UserReports/" + userReportId);
    }

    public async Task<HttpResponseMessage> GetUserReports(GetUserReportDto dto)
    {
        return await _client.PostAsJsonAsync("/UserReports/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserReport(String userReportId)
    {
        return await _client.GetAsync("/UserReports/" + userReportId);
    }
}
