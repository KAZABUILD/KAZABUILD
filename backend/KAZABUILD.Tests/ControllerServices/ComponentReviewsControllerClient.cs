using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentReview;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentReviewsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponentReview(CreateComponentReviewDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentReviews/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentReview(String componentReviewId, UpdateComponentReviewDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentReviews/"+componentReviewId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentReview(String componentReviewId)
    {
        return await _client.DeleteAsync("/ComponentReviews/"+componentReviewId);
    }

    public async Task<HttpResponseMessage> GetComponentReviews(GetComponentReviewDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentReviews/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentReview(String componentReviewId)
    {
        return await _client.GetAsync("/ComponentReviews/"+componentReviewId);
    }
}
