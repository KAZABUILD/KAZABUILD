using KAZABUILD.Application.Health;
using KAZABUILD.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding health checks to the app services
    public static class HealthCheckServiceCollectionExtensions
    {
        public static IServiceCollection AddAppHealthChecks(this IServiceCollection services)
        {
            //Add health checks
            services.AddHealthChecks()
                .AddDbContextCheck<KAZABUILDDBContext>("Database")
                .AddCheck<RabbitMQHealthCheck>("RabbitMQ")
                .AddCheck<SmtpHealthCheck>("SMTP");

            //Return the services with added health chcks
            return services;
        }
    }
}
