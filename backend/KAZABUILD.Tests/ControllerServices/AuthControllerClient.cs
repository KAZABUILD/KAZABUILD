using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Auth;

namespace KAZABUILD.Tests.ControllerServices;

public class AuthControllerClient
{
    private readonly HttpClient _client;

    public AuthControllerClient(HttpClient client)
    {
        _client = client;
    }

    public async Task<HttpResponseMessage> Login(LoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> Verify2Fa(Verify2FactorAuthenticationDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> GoogleLogin(GoogleLoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> Register(RegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> ConfirmRegister(ConfirmRegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> ResetPassword(ResetPasswordDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> ConfirmResetPassword(ConfirmPasswordResetDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }
}
