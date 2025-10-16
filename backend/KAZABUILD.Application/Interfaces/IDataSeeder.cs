namespace KAZABUILD.Application.Interfaces
{
    public interface IDataSeeder
    {
        Task<List<T2>> SeedAsync<T, T2>(int count, List<Guid>? ids1, List<Guid>? ids2, List<string>? idsOptional, string password) where T : class;
    }
}
