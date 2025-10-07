namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Used to differentiate kinds of token requested by users in the auth controller.
    /// </summary>
    public enum TokenType
    {
        LOGIN_2FA,
        CONFIRM_REGISTER,
        RESET_PASSWORD
    }
}
