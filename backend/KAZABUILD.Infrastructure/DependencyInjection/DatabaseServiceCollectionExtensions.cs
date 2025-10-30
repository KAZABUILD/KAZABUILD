using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Extension for adding the database to the app services.
    /// </summary>
    public static class DatabaseServiceCollectionExtensions
    {
        /// <summary>
        /// Function for adding the database to the app services.
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration config)
        {
            //Use a build-time factory to resolve IHostEnvironment later
            services.AddDbContext<KAZABUILDDBContext>((serviceProvider, options) =>
            {
                var env = serviceProvider.GetRequiredService<IHostEnvironment>();

                //Check whether the project is being tested
                if (env.IsEnvironment("Testing")) //If testing mock the database
                {
                    //Log database setup
                    Console.WriteLine("Using InMemory DB for Testing environment (AddDatabase skipped SQL Server).");

                    //Mock the database
                    options.UseInMemoryDatabase("InMemoryDbForTesting");
                }
                else //Otherwise use the connection string from settings
                {
                    //Log database setup
                    Console.WriteLine($"Using SQL Server DB for {env.EnvironmentName} environment.");

                    //Use the connection string for a real database
                    options.UseSqlServer(config.GetConnectionString("DefaultConnection"));
                }
            });

            //Return the services with the database registered
            return services;
        }
    }
}
