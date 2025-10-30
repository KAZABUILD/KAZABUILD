using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

public abstract class BaseIntegrationTest : IClassFixture<KazaWebApplicationFactory>, IAsyncLifetime
{
    protected readonly KazaWebApplicationFactory _factory;
    protected KAZABUILDDBContext _context = null!;
    private IServiceScope _scope = null!;
    protected IDataSeeder _dataSeeder = null!;
    protected User _superAdmin;
    protected HttpClient _superAdminHttpClient;
    protected AdminControllerClient _adminControllerClient;
    protected IConfiguration _configuration = null!;

    private static bool _isSeeded = false;
    private static readonly object _seedLock = new();

    protected BaseIntegrationTest(KazaWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public virtual async Task InitializeAsync()
    {
        _scope = _factory.Services.CreateScope();
        _context = _scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
        _dataSeeder = _scope.ServiceProvider.GetRequiredService<IDataSeeder>();
        _configuration = _scope.ServiceProvider.GetRequiredService<IConfiguration>();

        _superAdmin = _context.Users.FirstOrDefault(u => u.UserRole == UserRole.SYSTEM);
        var superAdminPassword = _configuration["SYSTEM_ADMIN:Password"];
        _superAdminHttpClient = await HttpClientFactory.Create(_factory, _superAdmin, password: superAdminPassword);
        _adminControllerClient = new AdminControllerClient(_superAdminHttpClient);

        if (!_isSeeded)
        {
            lock (_seedLock)
            {
                if (_isSeeded)
                    return;

                _isSeeded = true;
            }

            await _adminControllerClient.Seed("password123!");
        }
        await _context.SaveChangesAsync();
    }

    public virtual Task DisposeAsync()
    {
        _context.Dispose();
        _scope.Dispose();
        return Task.CompletedTask;
    }
}
