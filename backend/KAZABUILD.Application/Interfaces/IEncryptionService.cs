namespace KAZABUILD.Application.Interfaces
{
    public interface IEncryptionService
    {
        (string CipherText, string IV) Encrypt(string plainText);
        string Decrypt(string cipherText, string iv);
    }
}
