using KAZABUILD.Application.DTOs.Components.Color;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Components
{
    /// <summary>
    /// Controller for Color related endpoints.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class ColorController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new Color for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddColor([FromBody] CreateColorDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Color already exists
            var user = await _db.Colors.FirstOrDefaultAsync(u => u.ColorCode == dto.ColorCode);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Color",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Color Already Created"
                );

                //Return proper error response
                return Conflict(new { message = "Color already exists!" });
            }

            //Create a color to add
            Color color = new()
            {
                ColorCode = dto.ColorCode,
                ColorName = dto.ColorName,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the color to the database
            _db.Colors.Add(color);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Convert the hex code string into a guid
            Guid guidId = GuidConversionHelper.FromString(dto.ColorCode);

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Color",
                ip,
                guidId,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Color Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("color.created", new
            {
                colorId = dto.ColorCode,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { color = "Color added successfully!", id = color.ColorCode });
        }

        /// <summary>
        /// API endpoint for updating the selected Color for Administration,
        /// the id is a string representing the hex code of the Color.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateColor(string id, [FromBody] UpdateColorDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the color to edit
            var color = await _db.Colors.FirstOrDefaultAsync(u => u.ColorCode == id);

            //Convert the hex code string into a guid
            Guid guidId = GuidConversionHelper.FromString(id);

            //Check if the color exists
            if (color == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Color",
                    ip,
                    guidId,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Color"
                );

                //Return not found response
                return NotFound(new { color = "Color not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update fields
            if (!string.IsNullOrWhiteSpace(dto.ColorName))
            {
                changedFields.Add("ColorName: " + color.ColorName);

                color.ColorName = dto.ColorName;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + color.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    color.Note = null;
                else
                    color.Note = dto.Note;
            }

            //Update edit timestamp
            color.LastEditedAt = DateTime.UtcNow;

            //Update the color
            _db.Colors.Update(color);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Color",
                ip,
                guidId,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("color.updated", new
            {
                colorId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { color = "Color updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Color specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ColorResponseDto>> GetColor(string id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Convert the hex code string into a guid
            Guid guidId = GuidConversionHelper.FromString(id);

            //Get the color to return
            var color = await _db.Colors.FirstOrDefaultAsync(u => u.ColorCode == id);
            if (color == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Color",
                    ip,
                    guidId,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Color"
                );

                //Return not found response
                return NotFound(new { color = "Color not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ColorResponseDto response;

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create color response
                response = new ColorResponseDto
                {
                    ColorCode = color.ColorCode,
                    ColorName = color.ColorName
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create color response
                response = new ColorResponseDto
                {
                    ColorCode = color.ColorCode,
                    ColorName = color.ColorName,
                    DatabaseEntryAt = color.DatabaseEntryAt,
                    LastEditedAt = color.LastEditedAt,
                    Note = color.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Color",
                ip,
                guidId,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("color.got", new
            {
                colorId = id,
                gotBy = currentUserId
            });

            //Return the color
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Colors with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ColorResponseDto>>> GetColors([FromBody] GetColorDto dto)
        {
            //Get color id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Colors.AsNoTracking();

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, c => c.ColorCode, c => c.ColorName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get colors with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<Color> colors = await query.ToListAsync();

            //Declare response variable
            List<ColorResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Colors";

                //Create a color response list
                responses = [.. colors.Select(color =>
                {
                    //Return a follow response
                    return new ColorResponseDto
                    {
                        ColorCode = color.ColorCode,
                        ColorName = color.ColorName
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Colors";

                //Create a color response list
                responses = [.. colors.Select(color => new ColorResponseDto
                {
                    ColorCode = color.ColorCode,
                    ColorName = color.ColorName,
                    DatabaseEntryAt = color.DatabaseEntryAt,
                    LastEditedAt = color.LastEditedAt,
                    Note = color.Note,
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Color",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("color.gotColors", new
            {
                colorIds = colors.Select(u => u.ColorCode),
                gotdBy = currentUserId
            });

            //Return the colors
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Color for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteColor(string id)
        {
            //Get color id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Convert the hex code string into a guid
            Guid guidId = GuidConversionHelper.FromString(id);

            //Get the color to delete
            var color = await _db.Colors.Include(c => c.Components).FirstOrDefaultAsync(u => u.ColorCode == id);
            if (color == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Color",
                    ip,
                    guidId,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Color"
                );

                //Return not found response
                return NotFound(new { color = "Color not found!" });
            }

            //Delete all associated ComponentVariants
            if(color.Components.Count != 0)
{
                _db.ComponentVariants.RemoveRange(color.Components);
            }

            //Delete the color
            _db.Colors.Remove(color);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Color",
                ip,
                guidId,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("color.deleted", new
            {
                colorId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { color = "Color deleted successfully!" });
        }
    }
}
