using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;

using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace KAZABUILD.Infrastructure.Services
{
    public class AuthorizationService(IOptions<JwtSettings> jwtOptions) : IAuthorizationService
    {
        private readonly JwtSettings _jwt = jwtOptions.Value;

        public string GenerateJwtToken(Guid userId, string email, UserRole role)
        {
            //Create claims for id, email and role
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
                new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, email),
                new Claim(ClaimTypes.Role, role.ToString())
            };

            //Generate new encrypted key and credentials
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Secret));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            //Create the authentication token
            var token = new JwtSecurityToken(
                issuer: _jwt.Issuer,
                audience: _jwt.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_jwt.ExpiryMinutes),
                signingCredentials: creds
            );

            //Return a new security token
            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
