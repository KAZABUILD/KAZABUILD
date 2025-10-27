using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using KAZABUILD.Domain.Entities.Users;
using Microsoft.AspNetCore.Mvc.Testing;
namespace KAZABUILD.Tests.Utils
{
    public static class HttpClientAssigner
    {
        public static async Task AssignUserToClientAsync(HttpClient client, User user)
        {
            var loginPayload = new
            {
                Login = user.Login,
                Password = "password123!"
            };

            var response = await client.PostAsJsonAsync("/Auth/login", loginPayload);

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Login failed with status code: {response.StatusCode} For user with rank: {user.UserRole} and login: {user.Login}");
            }
            else
            {
                Console.WriteLine("Login succeeded with status code: {response.StatusCode} For user with rank: {user.UserRole} and login: {user.Login}");
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
        public async static Task<HttpClient> Create(WebApplicationFactory<API.Program> factory, User user) {
            var client = factory.CreateClient();
            await HttpClientAssigner.AssignUserToClientAsync(client, user);
            return client;
        }

    }
}
