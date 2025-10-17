using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.Message;

namespace KAZABUILD.Tests.ControllerServices;

public class MessagesControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> SendMessage(CreateMessageDto dto)
    {
        return await _client.PostAsJsonAsync("/Messages/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateMessage(String messageId, UpdateMessageDto dto)
    {
        return await _client.PutAsJsonAsync("/Messages/"+messageId, dto);
    }

    public async Task<HttpResponseMessage> GetMessage(String messageId)
    {
        return await _client.GetAsync("/Messages/"+messageId);
    }

    public async Task<HttpResponseMessage> DeleteMessage(String messageId)
    {
        return await _client.DeleteAsync("/Messages/"+messageId);
    }

    public async Task<HttpResponseMessage> GetMessages(GetMessageDto dto)
    {
        return await _client.PostAsJsonAsync("/Messages/", dto);
    }
}
