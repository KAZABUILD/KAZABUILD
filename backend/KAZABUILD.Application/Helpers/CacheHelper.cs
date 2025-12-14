using KAZABUILD.Application.DTOs.Builds.BuildInteraction;
using KAZABUILD.Application.DTOs.Users.UserActivity;
using KAZABUILD.Application.DTOs.Users.UserCommentInteraction;
using KAZABUILD.Application.DTOs.Users.UserFollow;

namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Static helper class for caching various DTOs to cache.
    /// </summary>
    public static class CacheHelper
    {
        /// <summary>
        /// Allows caching user activity views.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        public static string GetUserActivityCountCacheKey(GetUserActivityDto dto)
        {
            //Convert the dto to json
            var json = System.Text.Json.JsonSerializer.Serialize(dto);

            //Convert the json to a hash using a sha256 key
            var hash = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(json)));

            //Return the hashed dto
            return $"UserActivityCount:{hash}";
        }

        /// <summary>
        /// Allows caching user follow counts.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        public static string GetUserFollowCountCacheKey(GetUserFollowDto dto)
        {
            //Convert the dto to json
            var json = System.Text.Json.JsonSerializer.Serialize(dto);

            //Convert the json to a hash using a sha256 key
            var hash = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(json)));

            //Return the hashed dto
            return $"UserFollowCount:{hash}";
        }
    }
}
