using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Infrastructure.Messaging;
using KAZABUILD.Infrastructure.Services;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding custom services to the app services
    public static class ServicesCollectionExtensions
    {
        public static IServiceCollection AddServices(this IServiceCollection services, IConfiguration config)
        {
            //Add hashing for passwords, tokens, etc.
            services.AddScoped<IHashingService, HashingService>();

            //Add email smtp service
            services.AddScoped<IEmailService, SmtpEmailService>();

            //Add authorization service
            services.AddScoped<IAuthorizationService, AuthorizationService>();

            //Add loggin service
            services.AddScoped<ILoggerService, LoggerService>();

            //Add logs and token cleanup service
            services.AddHostedService<CleanupService>();

            //Add the RabbitMQ queue service
            services.Configure<RabbitMQSettings>(config.GetSection("RabbitMq"));
            services.AddSingleton<IRabbitMqConnection, RabbitMQConnection>();
            services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();
            services.AddHostedService<RabbitMQConsumer>();

            //Return the services with all the custom services added
            return services;
        }
    }
}
