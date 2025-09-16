using KAZABUILD.Application.Settings;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding options to the app services
    public static class OptionsServiceCollectionExtensions
    {
        public static IServiceCollection AddOptions(this IServiceCollection services, IConfiguration config)
        {
            //Get JWT Authentication from appsettings
            services.AddOptions<JwtSettings>()
                .Bind(config.GetSection("JwtSettings"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get RabbitMQ queue settings from appsettings
            services.AddOptions<RabbitMQSettings>()
                .Bind(config.GetSection("RabbitMq"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get SMTP email service settings from appsettings
            services.AddOptions<SmtpSettings>()
                .Bind(config.GetSection("SmtpSettings"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get the allwed frontend origins from appsettings
            services.AddOptions<FrontendSettings>()
                .Bind(config.GetSection("AllowedFrontendOrigins"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get the frontend url for link redirect in the auth controller from appsettings
            services.AddOptions<FrontendHost>()
                .Bind(config.GetSection("Frontend"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get the frontend url for link redirect in the auth controller from appsettings
            services.AddOptions<SystemAdminSetings>()
                .Bind(config.GetSection("SYSTEM_ADMIN"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Return the services with all the options added
            return services;
        }
    }
}
