using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using KAZABUILD.Domain.Entities.Users;
using Microsoft.AspNetCore.Mvc.Testing;
namespace KAZABUILD.Tests.Utils
{
    public static class HttpClientAssigner
    {
        public static async Task AssignUserToClientAsync(HttpClient client, User user, string? ip = null, string? password = null)
        {
            // ensure there's a default IP if none provided
            ip ??= "127.0.0.1";
            password ??= "password123!";

            // Remove any existing values to avoid duplicates
            if (client.DefaultRequestHeaders.Contains("X-Forwarded-For"))
                client.DefaultRequestHeaders.Remove("X-Forwarded-For");
            if (client.DefaultRequestHeaders.Contains("X-Real-IP"))
                client.DefaultRequestHeaders.Remove("X-Real-IP");

            // Add the IP header(s)
            client.DefaultRequestHeaders.TryAddWithoutValidation("X-Forwarded-For", ip);
            client.DefaultRequestHeaders.TryAddWithoutValidation("X-Real-IP", ip);

            var loginPayload = new
            {
                Login = user.Login,
                Password = password
            };

            var response = await client.PostAsJsonAsync("/Auth/login", loginPayload);

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Login failed with status code: {response.StatusCode} For user with rank: {user.UserRole} and login: {user.Login}\n Message: {response.Content.ReadAsStringAsync().Result}");
            }
            else
            {
                Console.WriteLine($"Login succeeded with status code: {response.StatusCode} For user with rank: {user.UserRole} and login: {user.Login}");
            }

            var json = await response.Content.ReadAsStringAsync();

            //Handle token responses
            using var doc = JsonDocument.Parse(json);

            var token = doc.RootElement.GetProperty("token").GetString();
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new Exception("No token returned from login endpoint.");
            }

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }
    public static class HttpClientFactory
    {
        public async static Task<HttpClient> Create(WebApplicationFactory<API.Program> factory, User user, string? ip = null, string? password = null) {
            var client = factory.CreateClient();
            await HttpClientAssigner.AssignUserToClientAsync(client, user, ip, password);
            return client;
        }

    }
}
