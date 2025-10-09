namespace KAZABUILD.Domain.Enums
{
    public enum BuildStatus
    {
        /// <summary>
        /// Unpublished builds only visible to the user that created it.
        /// </summary>
        DRAFT,
        /// <summary>
        /// Publicly visible builds that were created by a user.
        /// </summary>
        PUBLISHED,
        /// <summary>
        /// Build officially created by the website team.
        /// </summary>
        OFFICIAL,
        /// <summary>
        /// Auto-generated builds for a user.
        /// </summary>
        GENERATED
    }
}
