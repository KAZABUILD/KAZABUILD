using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Tests.Utils;
using Microsoft.Extensions.DependencyInjection;

public abstract class BaseIntegrationTest : IClassFixture<KazaWebApplicationFactory>, IAsyncLifetime
{
    public readonly KazaWebApplicationFactory _factory;
    public KAZABUILDDBContext _context = null!;
    private IServiceScope _scope = null!;

    protected BaseIntegrationTest(KazaWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public virtual async Task InitializeAsync()
    {
        _factory.ResetDatabase();

        _scope = _factory.Services.CreateScope();
        _context = _scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();

        await _context.SaveChangesAsync();
    }

    public virtual Task DisposeAsync()
    {
        _context.Dispose();
        _scope.Dispose();
        return Task.CompletedTask;
    }
}
