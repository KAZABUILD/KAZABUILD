using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Security.Claims;

namespace KAZABUILD.Infrastructure.Middleware
{
    /// <summary>
    /// Custom middleware that makes is so ip banned users are treated as banned
    /// </summary>
    /// <param name="next"></param>
    /// <param name="db"></param>
    public class BannedClaimsMiddleware(RequestDelegate next, KAZABUILDDBContext db)
    {
        //Variable storing the next part of the pipeline
        private readonly RequestDelegate _next = next;

        //Variable storing the database
        private readonly KAZABUILDDBContext _db = db;

        //Cache for recent ip address calls
        private static readonly MemoryCache _cache = new(new MemoryCacheOptions());

        /// <summary>
        /// Function inserted in the API request process.
        /// Adds a claim for any anonymous user.
        /// </summary>
        /// <param name="context"></param>
        /// <returns></returns>
        public async Task Invoke(HttpContext context)
        {
            //Get the ip for the user
            var ip = context.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? context.Connection.RemoteIpAddress?.ToString();

            //Check if the Ip isn't null
            if (string.IsNullOrWhiteSpace(ip))
            {
                await _next(context);
                return;
            }

            //Get the ip from the cache first
            if (!_cache.TryGetValue(ip, out bool isBlocked))
            {
                //If the ip is not in cache query the database
                isBlocked = await db.BlockedIps.AnyAsync(b => b.IpAddress == ip);

                //Add the new ip to the cache for 10 minutes
                _cache.Set(ip, isBlocked, TimeSpan.FromMinutes(10));
            }

            //If the ip is blocked override the claim
            if (isBlocked)
            {
                //If the user is authenticated, we override their role claim
                var claims = context.User.Claims.ToList();

                //Get and remove the role claim from the user
                var roleClaim = claims.FirstOrDefault(c => c.Type == ClaimTypes.Role);
                if (roleClaim != null)
                    claims.Remove(roleClaim);

                //Add a new banned role to the user claim
                claims.Add(new Claim(ClaimTypes.Role, UserRole.BANNED.ToString()));

                //Create an identity with the guest user
                var identity = new ClaimsIdentity(claims, "IpBlockOverride");

                //Replace the now banned user with the new identity
                context.User = new ClaimsPrincipal(identity);
            }

            //Continue the request flow and propagate the context
            await _next(context);
        }
    }
}
