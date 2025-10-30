namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Importance level used for logging.
    /// Determines whether the log remains or is deleted after a while from the database.
    /// </summary>
    public enum PrivacyLevel
    {
        /// <summary>
        /// Information about an event taking place.
        /// </summary>
        INFORMATION = 0,
        /// <summary>
        /// Warning for a request failing.
        /// </summary>
        WARNING = 1,
        /// <summary>
        /// An error in the working of the program. Means that a part of the program failed, while allowing it to continue functioning.
        /// </summary>
        ERROR = 2,
        /// <summary>
        /// Critical errors that crash the programs or disallow it from functioning properly anymore.
        /// </summary>
        CRITICAL = 3
    }
}
