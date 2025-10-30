using KAZABUILD.Application.Health;
using KAZABUILD.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Extension for adding health checks to the app services.
    /// </summary>
    public static class HealthCheckServiceCollectionExtensions
    {
        /// <summary>
        /// Function for adding health checks to the app services.
        /// </summary>
        /// <param name="services"></param>
        /// <returns></returns>
        public static IServiceCollection AddAppHealthChecks(this IServiceCollection services)
        {
            //Add health checks
            services.AddHealthChecks()
                .AddDbContextCheck<KAZABUILDDBContext>("Database")
                .AddCheck<RabbitMQHealthCheck>("RabbitMQ")
                .AddCheck<SmtpHealthCheck>("SMTP");

            //Return the services with added health checks
            return services;
        }
    }
}
