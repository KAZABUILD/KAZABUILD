namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// User profile access level for individual users.
    /// </summary>
    public enum ProfileAccessibility
    {
        /// <summary>
        /// All users can view the profile.
        /// </summary>
        PUBLIC,
        /// <summary>
        /// Only staff can view the profile.
        /// </summary>
        PRIVATE,
        /// <summary>
        /// Only used followed by the owner of the account can view the profile.
        /// </summary>
        FOLLOWS
    }
}
