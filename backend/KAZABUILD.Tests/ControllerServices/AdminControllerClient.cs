using System.Net.Http.Json;

namespace KAZABUILD.Tests.ControllerServices;

public class AdminControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> ResetSystemAdmin()
    {
        return await _client.PostAsJsonAsync("/Admin/reset", new {});
    }

    public async Task<HttpResponseMessage> Seed(String password)
    {
        return await _client.PostAsJsonAsync("/Admin/seed/"+password, new {});
    }
}
