using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
        {
            services.AddDatabase(config)
                    .AddOptions(config)
                    .AddAuthentication(config)
                    .AddRolePolicies()
                    .AddAppHealthChecks()
                    .AddServices(config)
                    .AddRateLimiting();

            return services;
        }
    }
}
