namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Response Dto for the login authorization.
    /// </summary>
    public class TokenResponseDto
    {
        /// <summary>
        /// The jwt token used for login.
        /// </summary>
        public string? Token { get; set; }
    }
}
