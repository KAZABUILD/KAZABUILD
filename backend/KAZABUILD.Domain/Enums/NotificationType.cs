namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Type of notification sent.
    /// Determines the way it's displayed to the user.
    /// </summary>
    public enum NotificationType
    {
        NONE,
        /// <summary>
        /// Reminder about events on the website.
        /// Can be used to notify about unread messages.
        /// </summary>
        REMINDER,
        /// <summary>
        /// Shop offer.
        /// </summary>
        OFFER,
        /// <summary>
        /// Admin created notifications.
        /// </summary>
        ADMIN
    }
}
