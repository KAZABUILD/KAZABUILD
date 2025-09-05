using KAZABUILD.Application.Health;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Infrastructure.Messaging;
using KAZABUILD.Infrastructure.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Threading.RateLimiting;

namespace KAZABUILD.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
        {
            //Register the database context
            services.AddDbContext<KAZABUILDDBContext>(options =>
                options.UseSqlServer(config.GetConnectionString("DefaultConnection")));

            //Get JWT Authentication from appsettings
            services.AddOptions<JwtSettings>()
                .Bind(config.GetSection("JwtSettings"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            services.AddOptions<RabbitMQSettings>()
                .Bind(config.GetSection("RabbitMq"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            services.AddOptions<SmtpSettings>()
                .Bind(config.GetSection("SmtpSettings"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            services.AddOptions<FrontendSettings>()
                .Bind(config.GetSection("AllowedFrontendOrigins"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            //Get jwt information from saved settings
            var jwt = config.GetSection("JwtSettings").Get<JwtSettings>()!;
            var key = Encoding.UTF8.GetBytes(jwt.Secret);

            //Add authentication
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
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

            //Add authorization
            services.AddAuthorization(options =>
            {
                //Add a policy for every role
                foreach (var r in Enum.GetNames<UserRole>())
                {
                    options.AddPolicy(r, policy => policy.RequireRole(r));
                }

                //Add a policies for all role groups
                options.AddPolicy("AllUsers", policy =>
                    policy.RequireRole(RoleGroups.AllUsers));

                options.AddPolicy("Staff", policy =>
                    policy.RequireRole(RoleGroups.Staff));

                options.AddPolicy("Admins", policy =>
                    policy.RequireRole(RoleGroups.Admins));

                options.AddPolicy("SuperAdmins", policy =>
                    policy.RequireRole(RoleGroups.SuperAdmins));
            });

            //Add health checks
            services.AddHealthChecks()
                .AddDbContextCheck<KAZABUILDDBContext>("Database")
                .AddCheck<RabbitMQHealthCheck>("RabbitMQ")
                .AddCheck<SmtpHealthCheck>("SMTP");

            //Add hashing for passwords, tokens, etc.
            services.AddScoped<IHashingService, HashingService>();

            //Add email smtp service
            services.AddScoped<IEmailService, SmtpEmailService>();

            //Add authorization service
            services.AddScoped<IAuthorizationService, AuthorizationService>();

            //Add the RabbitMQ queue service
            services.Configure<RabbitMQSettings>(config.GetSection("RabbitMq"));
            services.AddSingleton<IRabbitMqConnection, RabbitMQConnection>();
            services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();
            services.AddHostedService<RabbitMQConsumer>();

            //Add rate limiting middleware
            services.AddRateLimiter(options =>
            {
                //Limiter policy to add to controllers
                options.AddPolicy("Fixed", context =>
                    RateLimitPartition.GetFixedWindowLimiter(
                        partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "anon",
                        factory: _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 100,
                            Window = TimeSpan.FromMinutes(1),
                            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                            QueueLimit = 2
                        }));

                //Global rate limit
                options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
                {
                    return RateLimitPartition.GetFixedWindowLimiter(
                        partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                        factory: _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 100,
                            Window = TimeSpan.FromSeconds(10),
                            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                            QueueLimit = 2
                        });
                });

                //Limiter reject status message code
                options.RejectionStatusCode = 429;
            });

            return services;
        }
    }
}
