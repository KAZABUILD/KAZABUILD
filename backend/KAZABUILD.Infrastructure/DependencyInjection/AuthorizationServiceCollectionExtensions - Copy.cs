using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding authorization to the app services
    public static class AuthorizationServiceCollectionExtensions
    {
        public static IServiceCollection AddRolePolicies(this IServiceCollection services)
        {
            //Add authorization
            services.AddAuthorization(options =>
            {
                //Add a policy for every role
                foreach (var r in Enum.GetNames<UserRole>())
                {
                    options.AddPolicy(r, policy => policy.RequireRole(r));
                }

                //Add a policies for all role groups
                options.AddPolicy("AllUsers", policy => policy.RequireRole(RoleGroups.AllUsers));
                options.AddPolicy("Staff", policy => policy.RequireRole(RoleGroups.Staff));
                options.AddPolicy("Admins", policy => policy.RequireRole(RoleGroups.Admins));
                options.AddPolicy("SuperAdmins", policy => policy.RequireRole(RoleGroups.SuperAdmins));
            });

            //Return the services with added authorization
            return services;
        }
    }
}
