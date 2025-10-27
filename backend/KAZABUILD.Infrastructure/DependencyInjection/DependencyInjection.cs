using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Main dependency injection class.
    /// </summary>
    public static class DependencyInjection
    {
        /// <summary>
        /// Adds all custom injections to the program infrastructure.
        /// Has to be run in Program.cs once.
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
        {
            services
                .AddDatabase(config)
                .AddOptions(config)
                .AddAppAuthentication(config)
                .AddRolePolicies()
                .AddAppHealthChecks()
                .AddServices(config)
                .AddRateLimiting();

            return services;
        }
    }
}
