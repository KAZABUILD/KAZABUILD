using KAZABUILD.Domain.Enums;
using Microsoft.AspNetCore.Http;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace KAZABUILD.Infrastructure.Middleware
{
    /// <summary>
    /// Custom middleware that makes is so anonymous users are treated as guests.
    /// </summary>
    /// <param name="next"></param>
    public class GuestClaimsMiddleware(RequestDelegate next)
    {
        //Variable storing the next part of the pipeline
        private readonly RequestDelegate _next = next;

        /// <summary>
        /// Function inserted in the API request process.
        /// Adds a claim for any anonymous user.
        /// </summary>
        /// <param name="context"></param>
        /// <returns></returns>
        public async Task Invoke(HttpContext context)
        {
            //Check if the user doesn't have a claim already
            if (context.User?.Identity == null || !context.User.Identity.IsAuthenticated)
            {
                //Declare basic claim information
                var guestId = Guid.Empty;
                var guestRole = UserRole.GUEST.ToString();

                //Generate a new claim with a guest role assigned
                var claims = new[]
                {
                    new Claim(JwtRegisteredClaimNames.Sub, guestId.ToString()),
                    new Claim(ClaimTypes.NameIdentifier, guestId.ToString()),
                    new Claim(JwtRegisteredClaimNames.Email, string.Empty),
                    new Claim(ClaimTypes.Role, guestRole)
                };

                //Create an identity with the guest user
                var identity = new ClaimsIdentity(claims, "Guest");

                //Replace the null user with the new identity
                context.User = new ClaimsPrincipal(identity);
            }

            //Continue the request flow and propagate the context
            await _next(context);
        }
    }
}
