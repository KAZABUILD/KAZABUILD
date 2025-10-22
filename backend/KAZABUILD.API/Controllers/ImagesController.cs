using KAZABUILD.Application.DTOs.Image;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using Image = KAZABUILD.Domain.Entities.Image;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers
{
    /// <summary>
    /// Controller for Image related endpoints.
    /// Images can be added to: Comments, Forum Posts, Components, User Profiles, Builds
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    /// <param name="mediaSettings"></param>
    [ApiController]
    [Route("[controller]")]
    public class ImagesController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher, IOptions<MediaSettings> mediaSettings) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly MediaSettings _mediaSettings = mediaSettings.Value;

        /// <summary>
        /// API Endpoint for posting a new Image.
        /// User can add images to their own text fields, while administration can also add them for components.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddImage([FromForm] CreateImageDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Ensure the provided file exists
            if (dto.File == null || dto.File.Length == 0)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Provided File Doesn't Exist"
                );

                return BadRequest("No file uploaded.");
            }

            //Get the file extension
            var ext = Path.GetExtension(dto.File.FileName).ToLowerInvariant();

            //Check if the file is of an allowed type
            if (!_mediaSettings.AllowedFileTypes.Contains(ext))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid File Type"
                );

                return BadRequest($"File type {ext} not allowed.");
            }

            //Check if the file is within the size limit
            if (dto.File.Length > _mediaSettings.MaxFileSizeMB * 1024 * 1024)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - File Size Invalid"
                );

                return BadRequest($"File size exceeds the {_mediaSettings.MaxFileSizeMB}MB limit.");
            }

            //Check if current user has admin permissions if the file is of component type
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isAdmin = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Create an image to add
            Image image = new()
            {
                LocationType = dto.LocationType,
                Name = dto.Name,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the target id depending on the ImageLocationType
            switch (image.LocationType)
            {
                case ImageLocationType.BUILD:
                    //Set the target as build
                    image.BuildId = dto.TargetId;

                    //Check if the build exists and if the user owns it
                    var build = await _db.Builds.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (build == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Build Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Build not found!" });
                    }
                    else if (!isPrivileged && build.UserId != currentUserId)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }
                    break;
                case ImageLocationType.COMPONENT:
                    //Set the target as component
                    image.ComponentId = dto.TargetId;

                    //Check if the component exists
                    var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (component == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Component Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Component not found!" });
                    }
                    else if (!isAdmin)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }

                    break;
                case ImageLocationType.SUBCOMPONENT:
                    //Set the target as component
                    image.SubComponentId = dto.TargetId;

                    //Check if the component exists
                    var subComponent = await _db.SubComponents.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (subComponent == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - SubComponent Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "SubComponent not found!" });
                    }
                    else if (!isAdmin)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }

                    break;
                case ImageLocationType.COMMENT:
                    //Set the target as comment
                    image.UserCommentId = dto.TargetId;

                    //Check if the comment exists
                    var comment = await _db.UserComments.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (comment == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Review Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Review not found!" });
                    }
                    else if (!isPrivileged && comment.UserId != currentUserId)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }

                    break;
                case ImageLocationType.FORUM:
                    //Set the target as post
                    image.ForumPostId = dto.TargetId;

                    //Check if the post exists
                    var post = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (post == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - ForumPost Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "ForumPost not found!" });
                    }
                    else if (!isPrivileged && post.CreatorId != currentUserId)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }

                    break;
                case ImageLocationType.USER:
                    //Set the target as post
                    image.UserId = dto.TargetId;

                    //Check if the post exists
                    var user = await _db.ForumPosts.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (user == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - ForumPost Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "ForumPost not found!" });
                    }
                    else if (!isPrivileged && user.Id != currentUserId)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "Image",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Unauthorized Access"
                        );

                        //Return proper unauthorized response
                        return Forbid();
                    }

                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "Image",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper failure response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Declaration of the final location of the file.
            string savePath;

            try
            {
                //Create the directory if missing
                if (!Directory.Exists(_mediaSettings.StorageRootPath))
                    Directory.CreateDirectory(_mediaSettings.StorageRootPath);

                //Get file extension and name
                var fileExtension = Path.GetExtension(dto.File.FileName);
                var fileName = $"{Guid.NewGuid()}{fileExtension}";

                //Get the path to save the to
                savePath = Path.Combine(_mediaSettings.StorageRootPath, fileName);

                //Save the file
                await using var stream = new FileStream(savePath, FileMode.Create);
                await dto.File.CopyToAsync(stream);
            }
            catch(Exception ex)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    $"Operation Failed - File Save Failed With Error: {ex}"
                );

                //Return proper unauthorized response
                return BadRequest(new { message = "Saving File Failed!" });
            }

            //Add the save location to the image object
            image.Location = savePath;

            //Add the image to the database
            _db.Images.Add(image);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "Image",
                ip,
                image.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New Image Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.created", new
            {
                imageId = image.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Image added successfully!", id = image.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected Image.
        /// Only administration can modify images.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateImage(Guid id, [FromBody] UpdateImageDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the image to edit
            var image = await _db.Images.FirstOrDefaultAsync(c => c.Id == id);
            //Check if the image exists
            if (image == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "Image",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Image"
                );

                //Return not found response
                return NotFound(new { message = "Image not found!" });
            }

            //Check if current user has admin permissions or if they are modifying a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Return unauthorized access exception if the user does not have the correct permissions
            if (!isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return forbidden response
                return Forbid();
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.Name))
            {
                changedFields.Add("Name: " + image.Name);

                image.Name = dto.Name;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + image.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    image.Note = null;
                else
                    image.Note = dto.Note;
            }

            //Update edit timestamp
            image.LastEditedAt = DateTime.UtcNow;

            //Update the image
            _db.Images.Update(image);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "Image",
                ip,
                image.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.updated", new
            {
                imageId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Image updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the Image specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ImageResponseDto>> GetImage(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the image to return
            var image = await _db.Images.FirstOrDefaultAsync(c => c.Id == id);
            if (image == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Image",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Image"
                );

                //Return not found response
                return NotFound(new { message = "Image not found!" });
            }

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check the user has correct privileges or if the image isn't private
            if (!isPrivileged && !(image.User == null && image.Build == null) &&
                !(image.Build != null && (image.Build.UserId == currentUserId || (image.Build.Status != BuildStatus.GENERATED && image.Build.Status != BuildStatus.DRAFT)) &&
                !(image.User != null && (image.UserId == currentUserId || image.User.ProfileAccessibility == ProfileAccessibility.PUBLIC || (image.User.ProfileAccessibility == ProfileAccessibility.FOLLOWS && image.User.Followers.Any(f => f.FollowerId == currentUserId))))))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ImageResponseDto response;

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create image response
                response = new ImageResponseDto
                {
                    Id = image.Id,
                    Name = image.Name,
                    Location = image.Location,
                    LocationType = image.LocationType
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create image response
                response = new ImageResponseDto
                {
                    Id = image.Id,
                    Name = image.Name,
                    Location = image.Location,
                    LocationType = image.LocationType,
                    DatabaseEntryAt = image.DatabaseEntryAt,
                    LastEditedAt = image.LastEditedAt,
                    Note = image.Note
                };
            }

            //Add the target id depending on the CommentTargetType
            switch (image.LocationType)
            {
                case ImageLocationType.BUILD:
                    response.TargetId = image.BuildId;
                    break;
                case ImageLocationType.COMPONENT:
                    response.TargetId = image.ComponentId;
                    break;
                case ImageLocationType.SUBCOMPONENT:
                    response.TargetId = image.SubComponentId;
                    break;
                case ImageLocationType.USER:
                    response.TargetId = image.ComponentId;
                    break;
                case ImageLocationType.COMMENT:
                    response.TargetId = image.UserCommentId;
                    break;
                case ImageLocationType.FORUM:
                    response.TargetId = image.ForumPostId;
                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "GET",
                        "Image",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper unauthorized response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Image",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.got", new
            {
                imageId = id,
                gotBy = currentUserId
            });

            //Return the image
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting Images with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ImageResponseDto>>> GetImages([FromBody] GetImageDto dto)
        {
            //Get image id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.Images.AsNoTracking();

            //Filter by the variables if included
            if (dto.LocationType != null)
            {
                query = query.Where(i => dto.LocationType.Contains(i.LocationType));
            }
            if (dto.ForumPostId != null)
            {
                query = query.Where(i => i.ForumPostId != null && dto.ForumPostId.Contains((Guid)i.ForumPostId));
            }
            if (dto.BuildId != null)
            {
                query = query.Where(i => i.BuildId != null && dto.BuildId.Contains((Guid)i.BuildId));
            }
            if (dto.ComponentId != null)
            {
                query = query.Where(i => i.ComponentId != null && dto.ComponentId.Contains((Guid)i.ComponentId));
            }
            if (dto.SubComponentId != null)
            {
                query = query.Where(i => i.SubComponentId != null && dto.SubComponentId.Contains((Guid)i.SubComponentId));
            }
            if (dto.UserCommentId != null)
            {
                query = query.Where(i => i.UserCommentId != null && dto.UserCommentId.Contains((Guid)i.UserCommentId));
            }
            if (dto.UserId != null)
            {
                query = query.Where(i => i.UserId != null && dto.UserId.Contains((Guid)i.UserId));
            }

            //Apply search based on credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(i => i.User).Search(dto.Query, i => i.Name);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get images with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            //Get all queried images as a list, filter to exclude images the user cannot access
            List<Image> images = await query
                .Include(i => i.User)
                    .ThenInclude(u => u!.Followers)
                .Include(i => i.Build)
                .Where(i => isPrivileged || i.User == null || i.UserId == currentUserId || i.User.ProfileAccessibility == ProfileAccessibility.PUBLIC || (i.User.ProfileAccessibility == ProfileAccessibility.FOLLOWS && i.User.Followers.Any(f => f.FollowerId == currentUserId)))
                .Where(i => isPrivileged || i.Build == null || i.Build.UserId == currentUserId || (i.Build.Status != BuildStatus.GENERATED && i.Build.Status != BuildStatus.DRAFT))
                .ToListAsync();

            //Declare the failure check boolean
            bool failure = false;

            //Declare response variable
            List<ImageResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple Images";

                //Create a image response list
                responses = [.. images.Select(image =>
                {
                    //Create a response
                    var response = new ImageResponseDto
                    {
                        Id = image.Id,
                        LocationType = image.LocationType,
                        Name = image.Name,
                        Location = image.Location
                    };

                    //Add the target id depending on the CommentTargetType
                    switch (image.LocationType)
                    {
                        case ImageLocationType.BUILD:
                            response.TargetId = image.BuildId;
                            break;
                        case ImageLocationType.COMPONENT:
                            response.TargetId = image.ComponentId;
                            break;
                        case ImageLocationType.SUBCOMPONENT:
                            response.TargetId = image.SubComponentId;
                            break;
                        case ImageLocationType.USER:
                            response.TargetId = image.ComponentId;
                            break;
                        case ImageLocationType.COMMENT:
                            response.TargetId = image.UserCommentId;
                            break;
                        case ImageLocationType.FORUM:
                            response.TargetId = image.ForumPostId;
                            break;
                        default:
                            failure = true;
                            break;
                    }

                    return response;
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple Images";

                //Create a image response list
                responses = [.. images.Select(image =>
                {
                    //Create a response
                    var response = new ImageResponseDto
                    {
                        Id = image.Id,
                        LocationType = image.LocationType,
                        Name = image.Name,
                        Location = image.Location,
                        DatabaseEntryAt = image.DatabaseEntryAt,
                        LastEditedAt = image.LastEditedAt,
                        Note = image.Note
                    };

                    //Add the target id depending on the CommentTargetType
                    switch (image.LocationType)
                    {
                        case ImageLocationType.BUILD:
                            response.TargetId = image.BuildId;
                            break;
                        case ImageLocationType.COMPONENT:
                            response.TargetId = image.ComponentId;
                            break;
                        case ImageLocationType.SUBCOMPONENT:
                            response.TargetId = image.SubComponentId;
                            break;
                        case ImageLocationType.USER:
                            response.TargetId = image.ComponentId;
                            break;
                        case ImageLocationType.COMMENT:
                            response.TargetId = image.UserCommentId;
                            break;
                        case ImageLocationType.FORUM:
                            response.TargetId = image.ForumPostId;
                            break;
                        default:
                            failure = true;
                            break;
                    }

                    return response;
                })];
            }

            //Return failure if some assignment failed
            if (failure)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Target"
                );

                //Return proper unauthorized response
                return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Image",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.gotImages", new
            {
                imageIds = images.Select(c => c.Id),
                gotBy = currentUserId
            });

            //Return the images
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected Image.
        /// Users can delete images they sent and staff can delete all user related images.
        /// Only administration can delete component related images.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteImage(Guid id)
        {
            //Get image id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the image to delete
            var image = await _db.Images.Include(i => i.Build).Include(i => i.UserComment).Include(i => i.ForumPost).FirstOrDefaultAsync(c => c.Id == id);
            if (image == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Image",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Image"
                );

                //Return not found response
                return NotFound(new { message = "Image not found!" });
            }

            //Check if current user has admin or staff permissions or if they are deleting an image in their own entity
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isAdmin = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = (image.UserId != null && currentUserId == image.UserId) ||
                (image.Build != null && currentUserId == image.Build.UserId) ||
                (image.ForumPost != null && currentUserId == image.ForumPost.CreatorId) ||
                (image.UserComment != null && currentUserId == image.UserComment.UserId);

            //Check if the user has correct permission
            if (!isAdmin && !isSelf && !(isPrivileged && image.LocationType != ImageLocationType.COMPONENT && image.LocationType != ImageLocationType.SUBCOMPONENT))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "Image",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            if (System.IO.File.Exists(image.Location))
                System.IO.File.Delete(image.Location);

            //Delete the image
            _db.Images.Remove(image);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the deletion
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "Image",
                ip,
                image.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.deleted", new
            {
                imageId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Image deleted successfully!" });
        }

        /// <summary>
        /// Download the file through a controlled route.
        /// Users can download all images that aren't on private profiles.
        /// Staff can download all.
        /// Can be accessed in html like a link instead of fetching.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("download/{id}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DownloadImageFile(Guid id)
        {
            //Get image id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the image to download
            var image = await _db.Images.Include(i => i.Build).Include(i => i.User).ThenInclude(u => u!.Followers).FirstOrDefaultAsync(i => i.Id == id);
            if (image == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Image",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such Image"
                );

                //Return not found response
                return NotFound(new { message = "Image not found!" });
            }

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check the user has correct privileges or if the image isn't private
            if (!isPrivileged && !(image.User == null && image.Build == null) &&
                !(image.Build != null && (image.Build.UserId == currentUserId || (image.Build.Status != BuildStatus.GENERATED && image.Build.Status != BuildStatus.DRAFT))) &&
                !(image.User != null && (image.UserId == currentUserId || image.User.ProfileAccessibility == ProfileAccessibility.PUBLIC || (image.User.ProfileAccessibility == ProfileAccessibility.FOLLOWS && image.User.Followers.Any(f => f.FollowerId == currentUserId)))))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "Image",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the file exists
            if (!System.IO.File.Exists(image.Location))
                return NotFound();

            //Get the file and the type of its content
            var fileBytes = await System.IO.File.ReadAllBytesAsync(image.Location);
            var contentType = "image/" + Path.GetExtension(image.Location).TrimStart('.');

            //Log the download
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "Image",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - Image download started"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("image.downloaded", new
            {
                imageId = id,
                deletedBy = currentUserId
            });

            return File(fileBytes, contentType);
        }
    }
}
