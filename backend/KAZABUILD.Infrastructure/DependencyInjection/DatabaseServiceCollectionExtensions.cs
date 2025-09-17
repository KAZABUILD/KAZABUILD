using KAZABUILD.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding the database to the app services
    public static class DatabaseServiceCollectionExtensions
    {
        public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration config)
        {
            //Register the database context
            services.AddDbContext<KAZABUILDDBContext>(options =>
                options.UseSqlServer(config.GetConnectionString("DefaultConnection")));

            //Return the services with the database added
            return services;
        }
    }
}
