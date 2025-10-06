namespace KAZABUILD.Tests;

using System.Net;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Infrastructure.Services;
using KAZABUILD.Tests.Utils;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Mvc.Testing;
public class UserControllerTests : IClassFixture<WebApplicationFactory<API.Program>>, IAsyncLifetime
{
    private readonly WebApplicationFactory<API.Program> _factory;
    private readonly KAZABUILDDBContext _context;
    private HttpClient _client_user;
    private readonly DbTestUtils _utils = new();

    private User admin = UserFactory.GenerateUser(login: "temp_admin", role: UserRole.ADMINISTRATOR);
    private User user = UserFactory.GenerateUser(role: UserRole.USER);

    public UserControllerTests(WebApplicationFactory<API.Program> factory)
    {
        _factory = factory;
        _context = _utils.SetContextInMemory(_context);
    }

    public async Task InitializeAsync()
    {
        _context.Users.Add(admin);
        _context.Users.Add(user);
        _context.SaveChanges();

        _client_user = await HttpClientFactory.Create(_factory, user);
    }

    public Task DisposeAsync()
    {
        _context.Dispose();
        return Task.CompletedTask;
    }

    [Fact]
    public async Task UserWithLowerRankShouldntDeleteUserWithHigherRank()
    {
        var response = await _client_user.DeleteAsync($"/Users/{admin.Id}");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
