using KAZABUILD.Domain.Entities;

namespace KAZABUILD.Application.Helpers
{
    public static class EmailBodyHelper
    {
        public static string GetAccountConfirmationEmailBody(string displayName, string confirmUrl)
        {
            return $@"
                <html>
                <head>
                  <style>
                    body {{ font-family: Arial, sans-serif; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eaeaea; border-radius: 8px; }}
                    .button {{ display: inline-block; padding: 10px 20px; margin-top: 20px; background-color: #007BFF; color: #fff; text-decoration: none; border-radius: 5px; }}
                    .footer {{ margin-top: 30px; font-size: 12px; color: #888; }}
                  </style>
                </head>
                <body>
                  <div class='container'>
                    <h2>Welcome, {displayName}!</h2>
                    <p>Thank you for registering with our service. Please confirm your account by clicking the button below:</p>
                    <a class='button' href='{confirmUrl}'>Confirm Account</a>
                    <p>If you did not sign up for this account, please ignore this email.</p>
                    <div class='footer'>
                      &copy; {DateTime.Now.Year} KAZABUILD. All rights reserved.
                    </div>
                  </div>
                </body>
                </html>";
        }

        public static string GetPasswordResetEmailBody(string displayName, string confirmUrl)
        {
            return $@"
                <html>
                <head>
                  <style>
                    body {{ font-family: Arial, sans-serif; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eaeaea; border-radius: 8px; }}
                    .button {{ display: inline-block; padding: 10px 20px; margin-top: 20px; background-color: #28A745; color: #fff; text-decoration: none; border-radius: 5px; }}
                    .footer {{ margin-top: 30px; font-size: 12px; color: #888; }}
                  </style>
                </head>
                <body>
                  <div class='container'>
                    <h2>Hello, {displayName}</h2>
                    <p>We received a request to reset your password. Click the button below to proceed:</p>
                    <a class='button' href='{confirmUrl}'>Reset Password</a>
                    <p>If you did not request a password reset, you can safely ignore this email.</p>
                    <div class='footer'>
                      &copy; {DateTime.Now.Year} Your Company. All rights reserved.
                    </div>
                  </div>
                </body>
                </html>";
        }
    }
}
