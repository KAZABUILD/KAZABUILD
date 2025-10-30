namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Type of message specifying its source.
    /// </summary>
    public enum MessageType
    {
        /// <summary>
        /// Sent by another user.
        /// </summary>
        USER,
        /// <summary>
        /// Send by Staff.
        /// </summary>
        REQUEST,
        /// <summary>
        /// Send by administration.
        /// </summary>
        ADMIN,
        /// <summary>
        /// Automated message.
        /// </summary>
        SYSTEM,
        /// <summary>
        /// Ai ChatBot message.
        /// </summary>
        AI
    }
}
