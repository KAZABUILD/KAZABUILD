using KAZABUILD.Application.Settings;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Extension for adding options from appsettings.json to the app services.
    /// </summary>
    public static class OptionsServiceCollectionExtensions
    {
        /// <summary>
        /// Function for adding options from appsettings.json to the app services.
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        /// <returns></returns>
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

            //Get the allowed frontend origins and redirect urls from appsettings
            //Also used for CORS
            services.AddOptions<FrontendSettings>()
                .Bind(config.GetSection("Frontend"))
                .ValidateDataAnnotations()
                .Validate(settings => settings.AllowedFrontendOrigins != null, "Any frontend allowed URL has to be provided for the app to build!")
                .ValidateOnStart();

            //Get the backend url for link redirect in the auth controller from appsettings
            services.AddOptions<BackendHost>()
                .Bind(config.GetSection("Backend"))
                .ValidateDataAnnotations()
                .ValidateOnStart();


            //Get the frontend url for link redirect in the auth controller from appsettings
            services.AddOptions<SystemAdminSetings>()
                .Bind(config.GetSection("SYSTEM_ADMIN"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get the OAuth settings from appsettings
            services.AddOptions<OAuthSettings>()
                .Bind(config.GetSection("Authentication"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get the Media settings from appsettings
            services.AddOptions<MediaSettings>()
                .Bind(config.GetSection("Media"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Return the services with all the options added
            return services;
        }
    }
}
