using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Infrastructure.Messaging;
using KAZABUILD.Infrastructure.Services;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Extension for adding custom services to the app services.
    /// </summary>
    public static class ServicesCollectionExtensions
    {
        /// <summary>
        /// Function for adding custom services to the app services.
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static IServiceCollection AddServices(this IServiceCollection services, IConfiguration config)
        {
            //Add hashing for passwords, tokens, etc.
            services.AddScoped<IHashingService, HashingService>();

            //Add email smtp service
            services.AddScoped<IEmailService, SmtpEmailService>();

            //Add authorization service
            services.AddScoped<IAuthorizationService, AuthorizationService>();

            //Add logging service
            services.AddScoped<ILoggerService, LoggerService>();

            //Add logs and token cleanup service
            services.AddHostedService<CleanupService>();

            //Add Ip blocklist automatic unban service
            services.AddHostedService<UnbanUserService>();

            //Add the RabbitMQ queue service
            services.Configure<RabbitMQSettings>(config.GetSection("RabbitMq"));
            services.AddSingleton<IRabbitMqConnection, RabbitMQConnection>();
            services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();
            services.AddHostedService<RabbitMQConsumer>();

            //Add the cleanup service
            services.AddScoped<IDataSeeder, DataSeeder>();

            //Return the services with all the custom services added
            return services;
        }
    }
}
