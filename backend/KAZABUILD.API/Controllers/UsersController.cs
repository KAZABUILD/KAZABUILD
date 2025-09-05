using KAZABUILD.Application.DTOs.User;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ILogger = KAZABUILD.Application.Interfaces.ILogger;

namespace KAZABUILD.API.Controllers
{
    //Controller for user related endpoints
    [ApiController]
    [Route("[controller]")]
    // [EnableRateLimiting("Fixed")] <- Uncomment to add rate limiting
    public class UsersController(KAZABUILDDBContext db, ILogger logger, IHashingService hasher, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILogger _logger = logger;
        private readonly IHashingService _hasher = hasher;
        private readonly IRabbitMQPublisher _publisher = publisher;

        //Update the selected user's profile
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the ip from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user is editing themselves or if they have staff permissions
            var isSelf = currentUserId == id;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //return unathorized access exception if the user does not have the correct permiossions
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "UPDATE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - unathorized access"
                );

                return Forbid();
            }

            //Get the user to edit
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "UPDATE",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.INFORMATION,
                    "Operation Failed - no such user"
                );

                //Return not found response
                return NotFound(new { message = "User not found!" });
            }

            //Update allowed fields
            if (!string.IsNullOrEmpty(dto.DisplayName)) user.DisplayName = dto.DisplayName;
            if (!string.IsNullOrEmpty(dto.PhoneNumber)) user.PhoneNumber = dto.PhoneNumber;
            if (!string.IsNullOrEmpty(dto.Description)) user.Description = dto.Description;
            if (!string.IsNullOrEmpty(dto.Gender)) user.Gender = dto.Gender;
            if (!string.IsNullOrEmpty(dto.ImageUrl)) user.ImageUrl = dto.ImageUrl;

            //Update allowed fields - administration
            if (isPrivileged)
            {
                if (!string.IsNullOrEmpty(dto.Email)) user.Email = dto.Email;
            }

            //Hash password if provided
            if (!string.IsNullOrEmpty(dto.Password) && isPrivileged)
            {
                user.PasswordHash = _hasher.Hash(dto.Password);
            }

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "UPDATE",
                "User",
                ip,
                user.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("user.profile.updated", new
            {
                userId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User profile updated successfully!" });
        }
    }
}
