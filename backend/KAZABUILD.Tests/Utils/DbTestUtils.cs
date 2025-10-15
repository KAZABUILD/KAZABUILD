namespace KAZABUILD.Tests.Utils
{
    public class DbTestUtils
    {
        private readonly String DatabaseName = "kazabuild_db";
        private static Random _random = new Random();

        public static string RandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz";
            return new string(Enumerable.Repeat(chars, length)
                .Select(s => s[_random.Next(s.Length)]).ToArray());
        }

        public static string RandomEmail()
        {
            return $"{RandomString(6)}@{RandomString(4)}.com";
        }

        public static string RandomPhone()
        {
            return $"+1{_random.Next(1000000000, 1999999999)}";
        }

        public static string RandomUrl()
        {
            return $"https://picsum.photos/id/{_random.Next(1, 1000)}/200/200";
        }

    }
}
