using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System.Threading.RateLimiting;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding reate limiting to the app services
    public static class RateLimitingServiceCollectionExtensions
    {
        public static IServiceCollection AddRateLimiting(this IServiceCollection services)
        {
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

            //Return the services with rate limiting added
            return services;
        }
    }
}
