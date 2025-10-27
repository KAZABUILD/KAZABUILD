using KAZABUILD.Application.Interfaces;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Tests.Utils;
using Microsoft.Extensions.DependencyInjection;

public abstract class BaseIntegrationTest : IClassFixture<KazaWebApplicationFactory>, IAsyncLifetime
{
    protected readonly KazaWebApplicationFactory _factory;
    protected KAZABUILDDBContext _context = null!;
    private IServiceScope _scope = null!;
    protected IDataSeeder _dataSeeder = null!;

    protected BaseIntegrationTest(KazaWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public virtual async Task InitializeAsync()
    {
        _factory.ResetDatabase();

        _scope = _factory.Services.CreateScope();
        _context = _scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
        _dataSeeder = _scope.ServiceProvider.GetRequiredService<IDataSeeder>();

        await _context.SaveChangesAsync();
    }

    public virtual Task DisposeAsync()
    {
        _context.Dispose();
        _scope.Dispose();
        return Task.CompletedTask;
    }
}
