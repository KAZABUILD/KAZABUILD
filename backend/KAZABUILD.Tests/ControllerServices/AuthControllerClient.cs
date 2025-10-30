using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Auth;

namespace KAZABUILD.Tests.ControllerServices;

public class AuthControllerClient
{
    HttpClient _client;

    public AuthControllerClient(HttpClient client)
    {
        _client = client;
    }

    public async Task<HttpResponseMessage> login(LoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> verify2fa(Verify2FactorAuthenticationDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> googleLogin(GoogleLoginDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> register(RegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> confirmRegister(ConfirmRegisterDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> resetPassword(ResetPasswordDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }

    public async Task<HttpResponseMessage> confirmResetPassword(ConfirmPasswordResetDto dto)
    {
        return await _client.PostAsJsonAsync("/Auth/login", dto);
    }
}
