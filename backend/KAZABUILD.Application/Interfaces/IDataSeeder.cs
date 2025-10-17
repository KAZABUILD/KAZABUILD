namespace KAZABUILD.Application.Interfaces
{
    public interface IDataSeeder
    {
        Task<List<T2>> SeedAsync<T, T2>(int count = 100, List<Guid>? ids1 = null, List<Guid>? ids2 = null, List<Guid>? ids3 = null, List<Guid>? ids4 = null, List<Guid>? ids5 = null, List<string>? idsOptional = null, string? password = "password123!") where T : class;
    }
}
