using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.Notification;

namespace KAZABUILD.Tests.ControllerServices;

public class NotificationsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddNotification(CreateNotificationDto dto)
    {
        return await _client.PostAsJsonAsync("/Notifications/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateNotification(String notificationId, UpdateNotificationDto dto)
    {
        return await _client.PutAsJsonAsync("/Notifications/"+notificationId, dto);
    }

    public async Task<HttpResponseMessage> DeleteNotification(String notificationId)
    {
        return await _client.DeleteAsync("/Notifications/"+notificationId);
    }

    public async Task<HttpResponseMessage> GetNotifications(GetNotificationDto dto)
    {
        return await _client.PostAsJsonAsync("/Notifications/get", dto);
    }

    public async Task<HttpResponseMessage> GetNotification(String notificationId)
    {
        return await _client.GetAsync("/Notifications/"+notificationId);
    }
}
