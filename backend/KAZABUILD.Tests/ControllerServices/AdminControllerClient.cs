using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Admin;

namespace KAZABUILD.Tests.ControllerServices;

public class AdminControllerClient(HttpClient _client): BaseApiControllerService
{
    public async Task<HttpResponseMessage> ResetSystemAdmin()
    {
        return await _client.PostAsJsonAsync("/Admin/reset", new {});
    }

    public async Task<HttpResponseMessage> Seed(String password)
    {
        return await _client.PostAsJsonAsync("/Admin/seed/"+password, new {});
    }

    public async Task<HttpResponseMessage> ResetDatabase()
    {
        return await _client.PostAsJsonAsync("/Admin/reset-database", new {});
    }

    public async Task<HttpResponseMessage> BlockIp(BlockIpRequestDto request)
    {
        return await _client.PostAsJsonAsync("/Admin/block-ip", request);
    }

    public async Task<HttpResponseMessage> GetBlocklist()
    {
        return await _client.GetAsync("/Admin/block-ip");
    }

    public async Task<HttpResponseMessage> UnblockIp(string ipAddress)
    {
        return await _client.DeleteAsync("/Admin/block-ip/"+ipAddress);
    }

}
