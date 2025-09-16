using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Enums;

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using System.Security.Claims;
using System.Threading.RateLimiting;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding reate limiting to the app services
    public static class RateLimitingServiceCollectionExtensions
    {
        public static IServiceCollection AddRateLimiting(this IServiceCollection services)
        {
            //Add a specific rate limiting middleware for controllers
            services.AddRateLimiter(options =>
            {
                //Limiter policy to add to controllers
                options.AddPolicy("Fixed", context =>
                {
                    //Get user role
                    var currentUserRole = Enum.Parse<UserRole>(context.User.FindFirstValue(ClaimTypes.Role)!);
                    var isAdmin = RoleGroups.Admins.Contains(currentUserRole.ToString());

                    //Check if user is an admin or higher
                    if (isAdmin)
                    {
                        //Return unlimited limiter for admins
                        return RateLimitPartition.GetNoLimiter("admin");
                    }

                    //Return a default limiter for other users
                    return RateLimitPartition.GetFixedWindowLimiter(
                        partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "anon",
                        factory: _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 100,
                            Window = TimeSpan.FromSeconds(10),
                            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                            QueueLimit = 2
                        }
                    );
                });

                //Enable a global rate limit for every controller
                options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
                {
                    //Get user role
                    var currentUserRole = Enum.Parse<UserRole>(httpContext.User.FindFirstValue(ClaimTypes.Role)!);
                    var isAdmin = RoleGroups.Admins.Contains(currentUserRole.ToString());

                    //Check if user is an admin or higher
                    if (isAdmin)
                    {
                        //Return unlimited limiter for admins
                        return RateLimitPartition.GetNoLimiter("admin");
                    }

                    //Return a default limiter for other users
                    return RateLimitPartition.GetFixedWindowLimiter(
                        partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                        factory: _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 100,
                            Window = TimeSpan.FromSeconds(60),
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
