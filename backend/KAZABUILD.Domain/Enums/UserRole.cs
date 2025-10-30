namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Allows working with permissions, creates different levels off access for endpoints.
    /// Ordered from least permission to most;
    /// the order should not be changes and adding any new roles should be properly vetted, with correction being made in the controllers that use roles.
    /// </summary>
    public enum UserRole
    {
        /// <summary>
        /// User banned by moderation.
        /// </summary>
        BANNED = 0,
        /// <summary>
        /// Default role of non logged in users.
        /// </summary>
        GUEST = 1,
        /// <summary>
        /// Users who haven't accepted their account verification emails.
        /// </summary>
        UNVERIFIED = 2,
        /// <summary>
        /// Regular user role.
        /// </summary>
        USER = 3,
        /// <summary>
        /// Users with special privileges.
        /// </summary>
        VIP = 4,
        /// <summary>
        /// Staff role. Allows modifying user related elements of the application (forum, messages, profiles, etc.).
        /// </summary>
        MODERATOR = 5,
        /// <summary>
        /// Administration role. Allows modifying all elements of the application.
        /// </summary>
        ADMINISTRATOR = 6,
        /// <summary>
        /// SuperAdmin role. Allows to modify all elements of the application and to create administrators.
        /// </summary>
        OWNER = 7,
        /// <summary>
        /// Automated account role. Should only be used for testing/automated operations.
        /// The system account is the one that is registered for sending notification and company emails.
        /// </summary>
        SYSTEM = 8
    }
}
