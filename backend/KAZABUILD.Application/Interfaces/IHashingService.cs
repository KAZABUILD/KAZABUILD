namespace KAZABUILD.Application.Interfaces
{
    public interface IHashingService
    {
        string Hash(string value);
        bool Verify(string value, string hash);
    }
}
