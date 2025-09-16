using JwtSettings = KAZABUILD.Application.Settings.JwtSettings;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding authentication to the app services
    public static class AuthenticationServiceCollectionExtensions
    {
        public static IServiceCollection AddAuthentication(this IServiceCollection services, IConfiguration config)
        {
            //Get jwt information from saved settings
            var jwt = config.GetSection("JwtSettings").Get<JwtSettings>()!;
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
            });

            //Return the services with added authentication
            return services;
        }
    }
}
