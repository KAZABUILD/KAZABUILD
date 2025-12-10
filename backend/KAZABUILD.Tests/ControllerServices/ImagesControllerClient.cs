using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Image;

namespace KAZABUILD.Tests.ControllerServices;

public class ImagesControllerClient(HttpClient _client): BaseApiControllerService
{
    /// <summary>
    /// Add a new image with file upload
    /// </summary>
    public async Task<HttpResponseMessage> AddImage(CreateImageDto dto)
    {
        // Create multipart form data for file upload
        using var content = new MultipartFormDataContent();

        // Add the file
        if (dto.File != null)
        {
            var fileContent = new StreamContent(dto.File.OpenReadStream());
            fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(dto.File.ContentType);
            content.Add(fileContent, "File", dto.File.FileName);
        }

        // Add other properties
        content.Add(new StringContent(dto.LocationType.ToString()), "LocationType");
        content.Add(new StringContent(dto.TargetId.ToString()), "TargetId");

        if (!string.IsNullOrWhiteSpace(dto.Name))
            content.Add(new StringContent(dto.Name), "Name");

        return await _client.PostAsync("/Images/add", content);
    }

    /// <summary>
    /// Update an existing image
    /// </summary>
    public async Task<HttpResponseMessage> UpdateImage(string imageId, UpdateImageDto dto)
    {
        return await _client.PutAsJsonAsync($"/Images/{imageId}", dto);
    }

    /// <summary>
    /// Get a single image by ID
    /// </summary>
    public async Task<HttpResponseMessage> GetImage(string imageId)
    {
        return await _client.GetAsync($"/Images/{imageId}");
    }

    /// <summary>
    /// Get multiple images with filters
    /// </summary>
    public async Task<HttpResponseMessage> GetImages(GetImageDto dto)
    {
        return await _client.PostAsJsonAsync("/Images/get", dto);
    }

    /// <summary>
    /// Delete an image by ID
    /// </summary>
    public async Task<HttpResponseMessage> DeleteImage(string imageId)
    {
        return await _client.DeleteAsync($"/Images/{imageId}");
    }

    /// <summary>
    /// Download an image file
    /// </summary>
    public async Task<HttpResponseMessage> DownloadImage(string imageId)
    {
        return await _client.GetAsync($"/Images/download/{imageId}");
    }

    /// <summary>
    /// Download image and return byte array
    /// </summary>
    public async Task<byte[]?> DownloadImageBytes(string imageId)
    {
        var response = await DownloadImage(imageId);
        if (response.IsSuccessStatusCode)
        {
            return await response.Content.ReadAsByteArrayAsync();
        }
        return null;
    }
}
