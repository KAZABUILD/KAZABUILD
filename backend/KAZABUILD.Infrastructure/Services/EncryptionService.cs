using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;

using Microsoft.Extensions.Options;
using System.Text;
using System.Security.Cryptography;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Encryption service used to securely store messages between users.
    /// </summary>
    public class EncryptionService(IOptions<EncryptionSettings> settings) : IEncryptionService
    {
        //The key used to decrypt messages
        private readonly byte[] _key = Convert.FromBase64String(settings.Value.Key);

        /// <summary>
        /// Encrypt text using the key stored in the settings.
        /// </summary>
        /// <param name="plainText"></param>
        /// <returns></returns>
        public (string CipherText, string IV) Encrypt(string plainText)
        {
            //Create the aes cryptographic object
            using var aes = Aes.Create();

            //Set the key to the one used in the settings
            aes.Key = _key;

            //Generate a random initialization vector
            aes.GenerateIV();

            //Create the encryptor using the Key and IV
            using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

            //Transform the text into bytes and encrypt it 
            var plainBytes = Encoding.UTF8.GetBytes(plainText);
            var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

            //Return the cipher text and the iv
            return (Convert.ToBase64String(cipherBytes), Convert.ToBase64String(aes.IV));
        }

        /// <summary>
        /// Decrypts text using the key stored in the settings.
        /// </summary>
        /// <param name="cipherText"></param>
        /// <param name="iv"></param>
        /// <returns></returns>
        public string Decrypt(string cipherText, string iv)
        {
            //Create the aes cryptographic object
            using var aes = Aes.Create();

            //Set the key to the one used in the settings
            aes.Key = _key;

            //Set the initialization vector to the one provided
            aes.IV = Convert.FromBase64String(iv);

            //Create the decryptor using the Key and IV
            using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

            //Transform the cipher text into bytes and decrypt it 
            var cipherBytes = Convert.FromBase64String(cipherText);
            var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);

            //Return the plain text
            return Encoding.UTF8.GetString(plainBytes);
        }
    }
}
