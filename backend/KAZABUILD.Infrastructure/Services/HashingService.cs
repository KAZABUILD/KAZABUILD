using KAZABUILD.Application.Interfaces;

namespace KAZABUILD.Infrastructure.Services
{
    public class HashingService : IHashingService
    {
        public string Hash(string value) =>
            BCrypt.Net.BCrypt.HashPassword(value);

        public bool Verify(string value, string hash) =>
            BCrypt.Net.BCrypt.Verify(value, hash);
    }
}
