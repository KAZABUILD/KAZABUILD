using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Auth;

namespace KAZABUILD.Tests.ControllerServices;

public class AuthControllerClient
{
    private readonly HttpClient _client;
    private readonly string? _ipAddress;

    public AuthControllerClient(HttpClient client, string? ipAddress = null)
    {
        _client = client;
        _ipAddress = ipAddress;

        _client.DefaultRequestHeaders.Remove("X-Forwarded-For");
        _client.DefaultRequestHeaders.Add("X-Forwarded-For", _ipAddress);
    }

    public async Task<HttpResponseMessage> Login(LoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> Verify2Fa(Verify2FactorAuthenticationDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/verify-2fa", dto);
    }

    public async Task<HttpResponseMessage> GoogleLogin(GoogleLoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/google-login", dto);
    }

    public async Task<HttpResponseMessage> Register(RegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/register", dto);
    }

    public async Task<HttpResponseMessage> ConfirmRegister(ConfirmRegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/confirm-register", dto);
    }

    public async Task<HttpResponseMessage> ResetPassword(ResetPasswordDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/reset-password", dto);
    }

    public async Task<HttpResponseMessage> ConfirmResetPassword(ConfirmPasswordResetDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/confirm-reset-password", dto);
    }
}
