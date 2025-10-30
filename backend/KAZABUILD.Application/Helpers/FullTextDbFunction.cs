using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Application.Helpers
{
    public static class FullTextDbFunction
    {
        //Declaration for mapping the Full-Text Contains function so that it can be used in EF Core
        public static bool Contains(string property, string searchTerm) =>
            throw new NotSupportedException();

        //Declaration for mapping the Difference function so that it can be used in EF Core
        public static int Difference(DbFunctions _, string a, string b)
            => throw new NotSupportedException("This method is for SQL translation only.");
    }
}
