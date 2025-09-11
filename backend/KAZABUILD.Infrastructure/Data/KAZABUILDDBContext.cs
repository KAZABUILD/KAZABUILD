using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Infrastructure.Data
{
    public class KAZABUILDDBContext : DbContext
    {
        public KAZABUILDDBContext(DbContextOptions<KAZABUILDDBContext> options) : base(options) { }



    }
}
