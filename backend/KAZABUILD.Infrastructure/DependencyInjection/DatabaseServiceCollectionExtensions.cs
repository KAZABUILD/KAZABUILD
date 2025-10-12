using KAZABUILD.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding the database to the app services
    public static class DatabaseServiceCollectionExtensions
    {
        public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration config)
        {
            //Use a build-time factory to resolve IHostEnvironment later
            services.AddDbContext<KAZABUILDDBContext>((serviceProvider, options) =>
            {
                var env = serviceProvider.GetRequiredService<IHostEnvironment>();

                if (env.IsEnvironment("Testing"))
                {
                    Console.WriteLine("Using InMemory DB for Testing environment (AddDatabase skipped SQL Server).");
                    options.UseInMemoryDatabase("InMemoryDbForTesting");
                }
                else
                {
                    Console.WriteLine($"Using SQL Server DB for {env.EnvironmentName} environment.");
                    options.UseSqlServer(config.GetConnectionString("DefaultConnection"));
                }
            });

            return services;
        }
    }
}
