using KAZABUILD.Infrastructure.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Tests.Utils;
public class KazaWebApplicationFactory : WebApplicationFactory<API.Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            //Register new in-memory DB
            services.AddDbContext<KAZABUILDDBContext>(options =>
                options.UseInMemoryDatabase("InMemoryDbForTesting"));
        });
    }

    public void ResetDatabase()
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
        db.Database.EnsureDeleted();
        db.Database.EnsureCreated();
    }
}
