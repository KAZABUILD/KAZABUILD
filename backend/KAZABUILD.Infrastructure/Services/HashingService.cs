using KAZABUILD.Application.Interfaces;
using System.Linq.Dynamic.Core.Tokenizer;
using System.Security.Cryptography;
using System.Text;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service responsible for hashing and verifying previously hashed data.
    /// </summary>
    public class HashingService : IHashingService
    {
        /// <summary>
        /// Hash using SHA256 encryption.
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public string Hash(string value)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(value));
            return Convert.ToBase64String(hash);
        }

        public bool Verify(string value, string hash)
        {
            return Hash(value) == hash;
        }
    }
}
