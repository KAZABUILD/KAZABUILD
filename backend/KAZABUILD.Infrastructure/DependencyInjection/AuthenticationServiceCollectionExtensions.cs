using KAZABUILD.Application.Settings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using JwtSettings = KAZABUILD.Application.Settings.JwtSettings;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    /// <summary>
    /// Extension for adding authentication to the app services.
    /// </summary>
    public static class AuthenticationServiceCollectionExtensions
    {
        /// <summary>
        /// Function for adding authentication to the app services.
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static IServiceCollection AddAppAuthentication(this IServiceCollection services, IConfiguration config)
        {
            //Get jwt information from saved settings
            var jwt = config.GetSection("JwtSettings").Get<JwtSettings>()!;
            var google = config.GetSection("Authentication").Get<OAuthSettings>()!;
            var key = Encoding.UTF8.GetBytes(jwt.Secret);

            //Add authentication
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options => //Add automatic extraction of token from request headers
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwt.Issuer,
                    ValidAudience = jwt.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(key)
                };
            })
            .AddGoogle("Google", options =>
            {
                options.ClientId = google.Google.ClientId;
                options.ClientSecret = google.Google.ClientSecret;
            });

            //Return the services with added authentication
            return services;
        }
    }
}
