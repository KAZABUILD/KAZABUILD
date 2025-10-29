using KAZABUILD.Infrastructure.SMTP;
using MimeKit;
using MimeKit.Utils;

namespace KAZABUILD.Application.Helpers
{
    public static class EmailBodyHelper
    {
        public static EmailContent GetAccountConfirmationEmailBody(string displayName, string confirmUrl)
        {
            //Get the root folder and use it to get the application logo
            var projectRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, @"..\..\.."));
            var imagePath = Path.Combine(projectRoot, "wwwroot", "defaults", "kaza.png");

            //Try to get the logo from the bin as a safeguard
            if (!File.Exists(imagePath))
                imagePath = Path.Combine(AppContext.BaseDirectory, "wwwroot", "defaults", "kaza.png");

            //Generate an identifier to inbed an image in html
            var contentId = MimeUtils.GenerateMessageId();

            string body = $@"
                <html>
                <head>
                  <meta charset=""UTF-8"">
                  <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
                  <style>
                    * {{
                      margin: 0;
                      padding: 0;
                      box-sizing: border-box;
                    }}
    
                    body {{
                      font-family: Arial, sans-serif;
                      background-color: #1a1533;
                      color: #ffffff;
                      padding: 20px;
                      min-height: 100vh;
                    }}
    
                    .email-container {{
                      max-width: 1329px;
                      margin: 0 auto;
                      background-color: #1a1533;
                      position: relative;
                      padding: 40px 20px;
                    }}
    
                    .logo-section {{
                      text-align: left;
                      margin-bottom: 40px;
                    }}
    
                    .logo {{
                      width: 210px;
                      height: 210px;
                      margin-bottom: 20px;
                    }}
    
                    .brand-name {{
                      font-family: 'Quantico', sans-serif;
                      font-size: 96px;
                      color: #ffffff;
                      text-align: left;
                      margin-left: 36px;
                      margin-bottom: 60px;
                      line-height: 1.33;
                    }}
    
                    .display-name {{
                      font-family: Arial, sans-serif;
                      font-size: 32px;
                      color: #ffffff;
                      text-align: left;
                      margin-bottom: 40px;
                      line-height: 1.5;
                    }}
    
                    .content-section {{
                      max-width: 1100px;
                      margin: 0 auto;
                      text-align: left;
                      padding: 0 20px;
                    }}
    
                    .welcome-text {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      text-align: left;
                      margin-bottom: 40px;
                      line-height: 1.5;
                    }}
    
                    .confirm-button {{
                      display: inline-block;
                      background-color: #00e573;
                      color: #ffffff;
                      font-family: 'Quantico', sans-serif;
                      font-size: 64px;
                      text-align: left;
                      padding: 20px 50px;
                      border-radius: 28px;
                      text-decoration: none;
                      box-shadow: 0px 0px 20px 0px rgba(139, 92, 246, 0.3);
                      margin: 30px 0;
                      transition: transform 0.2s;
                    }}
    
                    .confirm-button:hover {{
                      transform: scale(1.05);
                    }}
    
                    .disclaimer-text {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      margin: 40px 0;
                      text-align:left;
                      line-height: 1.5;
                    }}
    
                    .divider {{
                      border: none;
                      border-top: 0.3px solid #999595;
                      margin: 60px 0 20px 0;
                    }}
    
                    .footer {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      text-align: center;
                      margin-top: 30px;
                    }}
    
                    .footer .brand-footer {{
                      font-family: 'Quantico', sans-serif;
                    }}
    
                    /* Mobile responsive */
                    @media only screen and (max-width: 768px) {{
                      .brand-name {{
                        font-size: 48px;
                        margin-left: 0;
                        text-align: center;
                      }}
      
                       .display-name {{
                            font-size: 24px;
                        }}
    
                      .confirm-button {{
                        font-size: 42px;
                        padding: 15px 35px;
                        display: block;
                        text-align: center;
                        margin: 30px auto;
                      }}
      
                      .welcome-text,
                      .disclaimer-text,
                      .footer {{
                        font-size: 16px;
                      }}
      
                      .logo-section {{
                        text-align: center;
                      }}
      
                      .logo {{
                        width: 150px;
                        height: 150px;
                        margin: 0 auto 20px;
                      }}
      
                      .content-section {{
                        text-align: left;
                      }}
                    }}
                  </style>
                  <!-- Google Fonts for Quantico -->
                  <link href=""https://fonts.googleapis.com/css2?family=Quantico:wght@400;700&display=swap"" rel=""stylesheet"">
                </head>
                <body>
                  <div class=""email-container"">
                    <!-- Logo Section -->
                    <div class=""logo"">
                      <img src=""cid:{contentId}"" alt=""KaZa Logo"" class=""logo"" />
                    </div>
    
                    <!-- Brand Name -->
                    <h1 class=""brand-name"">KazaBuild</h1>
    
                    <!-- Content Section -->
                    <div class=""content-section"">
                      <p class=""display-name"">
                        Welcome, {displayName}!
                      </p>
                      <p class=""welcome-text"">
                        Thank you for registering with our service. Please confirm your account by clicking the button below:
                      </p>
      
                      <!-- Confirm Button -->
                      <a class=""confirm-button"" href='{confirmUrl}'>Confirm</a>w                 

                      <!-- Disclaimer -->
                      <p class=""disclaimer-text"">
                        If you did not sign up for this account, please ignore this email.
                      </p>
                    </div>
    
                    <!-- Divider -->
                    <hr class=""divider"" />
    
                    <!-- Footer -->
                    <div class=""footer"">
                      <p>
                        <span>&copy; {DateTime.Now.Year} </span>
                        <span class=""brand-footer"">KAZABUILD</span>
                        <span>. All right reserved</span>
                      </p>
                    </div>
                  </div>
                </body>
                </html>";

            return new EmailContent
            {
                HtmlBody = body,
                ImagePath = imagePath,
                ContentId = contentId
            };
        }

        public static EmailContent GetPasswordResetEmailBody(string displayName, string confirmUrl)
        {
            //Get the root folder and use it to get the application logo
            var projectRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, @"..\..\.."));
            var imagePath = Path.Combine(projectRoot, "wwwroot", "defaults", "kaza.png");

            //Try to get the logo from the bin as a safeguard
            if (!File.Exists(imagePath))
                imagePath = Path.Combine(AppContext.BaseDirectory, "wwwroot", "defaults", "kaza.png");

            //Generate an identifier to inbed an image in html
            var contentId = MimeUtils.GenerateMessageId();

            string body = $@"
                 <html>
                <head>
                  <meta charset=""UTF-8"">
                  <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
                  <style>
                    * {{
                      margin: 0;
                      padding: 0;
                      box-sizing: border-box;
                    }}
    
                    body {{
                      font-family: Arial, sans-serif;
                      background-color: #1a1533;
                      color: #ffffff;
                      padding: 20px;
                      min-height: 100vh;
                    }}
    
                    .email-container {{
                      max-width: 1329px;
                      margin: 0 auto;
                      background-color: #1a1533;
                      position: relative;
                      padding: 40px 20px;
                    }}
    
                    .logo-section {{
                      text-align: left;
                      margin-bottom: 40px;
                    }}
    
                    .logo {{
                      width: 210px;
                      height: 210px;
                      margin-bottom: 20px;
                    }}
    
                    .brand-name {{
                      font-family: 'Quantico', sans-serif;
                      font-size: 96px;
                      color: #ffffff;
                      text-align: left;
                      margin-left: 36px;
                      margin-bottom: 60px;
                      line-height: 1.33;
                    }}
    
                    .display-name {{
                      font-family: Arial, sans-serif;
                      font-size: 32px;
                      color: #ffffff;
                      text-align: left;
                      margin-bottom: 40px;
                      line-height: 1.5;
                    }}
    
                    .content-section {{
                      max-width: 900px;
                      margin: 0 auto;
                      text-align: left;
                      padding: 0 20px;
                    }}
    
                    .welcome-text {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      text-align: left;
                      margin-bottom: 40px;
                      line-height: 1.5;
                    }}
    
                    .confirm-button {{
                      display: inline-block;
                      background-color: #00e573;
                      color: #ffffff;
                      font-family: 'Quantico', sans-serif;
                      font-size: 64px;
                      text-align: left;
                      padding: 20px 50px;
                      border-radius: 28px;
                      text-decoration: none;
                      box-shadow: 0px 0px 20px 0px rgba(139, 92, 246, 0.3);
                      margin: 30px 0;
                      transition: transform 0.2s;
                    }}
    
                    .confirm-button:hover {{
                      transform: scale(1.05);
                    }}
    
                    .disclaimer-text {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      margin: 40px 0;
                      text-align:left;
                      line-height: 1.5;
                    }}
    
                    .divider {{
                      border: none;
                      border-top: 0.3px solid #999595;
                      margin: 60px 0 20px 0;
                    }}
    
                    .footer {{
                      font-family: Arial, sans-serif;
                      font-size: 24px;
                      color: #ffffff;
                      text-align: center;
                      margin-top: 30px;
                    }}
    
                    .footer .brand-footer {{
                      font-family: 'Quantico', sans-serif;
                    }}
    
                    /* Mobile responsive */
                    @media only screen and (max-width: 768px) {{
                      .brand-name {{
                        font-size: 48px;
                        margin-left: 0;
                        text-align: center;
                      }}
      
                       .display-name {{
                            font-size: 24px;
                        }}
    
                      .confirm-button {{
                        font-size: 42px;
                        padding: 15px 35px;
                        display: block;
                        text-align: center;
                        margin: 30px auto;
                      }}
      
                      .welcome-text,
                      .disclaimer-text,
                      .footer {{
                        font-size: 16px;
                      }}
      
                      .logo-section {{
                        text-align: center;
                      }}
      
                      .logo {{
                        width: 150px;
                        height: 150px;
                        margin: 0 auto 20px;
                      }}
      
                      .content-section {{
                        text-align: left;
                      }}
                    }}
                  </style>
                  <!-- Google Fonts for Quantico -->
                  <link href=""https://fonts.googleapis.com/css2?family=Quantico:wght@400;700&display=swap"" rel=""stylesheet"">
                </head>
                <body>
                  <div class=""email-container"">
                    <!-- Logo Section -->
                    <div class=""logo"">
                      <img src=""cid:{contentId}"" alt=""KaZa Logo"" class=""logo"" />
                    </div>
    
                    <!-- Brand Name -->
                    <h1 class=""brand-name"">KazaBuild</h1>
    
                    <!-- Content Section -->

                    <div class=""content-section"">
                      <p class=""display-name"">
                        Hello, {displayName}
                      </p>
                      <p class=""welcome-text"">
                        We received a request to reset your password. Click the button below to proceed:
                      </p>
      
                      <!-- Confirm Button -->
                      <a class=""confirm-button"" href='{confirmUrl}'>Confirm</a>                 

                      <!-- Disclaimer -->
                      <p class=""disclaimer-text"">
                        If you did not request a password reset, you can safely ignore this email.
                      </p>
                    </div>

                    <!-- Divider -->
                    <hr class=""divider"" />
    
                    <!-- Footer -->
                    <div class=""footer"">
                      <p>
                        <span>&copy; {DateTime.Now.Year} </span>
                        <span class=""brand-footer"">KAZABUILD</span>
                        <span>. All right reserved</span>
                      </p>
                    </div>
                  </div>
                </body>
                </html>";

            return new EmailContent
            {
                HtmlBody = body,
                ImagePath = imagePath,
                ContentId = contentId
            };
        }

        public static EmailContent GetTwoFactorEmailBody(string displayName, string code)
        {
            //Get the root folder and use it to get the application logo
            var projectRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, @"..\..\.."));
            var imagePath = Path.Combine(projectRoot, "wwwroot", "defaults", "kaza.png");

            //Try to get the logo from the bin as a safeguard
            if (!File.Exists(imagePath))
                imagePath = Path.Combine(AppContext.BaseDirectory, "wwwroot", "defaults", "kaza.png");

            //Generate an identifier to inbed an image in html
            var contentId = MimeUtils.GenerateMessageId();

            string body = $@"
                 <html>
                 <head>
                   <meta charset=""UTF-8"">
                   <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
                   <style>
                     * {{
                       margin: 0;
                       padding: 0;
                       box-sizing: border-box;
                     }}
    
                     body {{
                       font-family: Arial, sans-serif;
                       background-color: #1a1533;
                       color: #ffffff;
                       padding: 20px;
                       min-height: 100vh;
                     }}
    
                     .email-container {{
                       max-width: 1329px;
                       margin: 0 auto;
                       background-color: #1a1533;
                       position: relative;
                       padding: 40px 20px;
                     }}
    
                     .logo-section {{
                       text-align: left;
                       margin-bottom: 40px;
                     }}
    
                     .logo {{
                       width: 210px;
                       height: 210px;
                       margin-bottom: 20px;
                     }}
    
                     .brand-name {{
                       font-family: 'Quantico', sans-serif;
                       font-size: 96px;
                       color: #ffffff;
                       text-align: left;
                       margin-left: 36px;
                       margin-bottom: 60px;
                       line-height: 1.33;
                     }}
    
                     .display-name {{
                      font-family: Arial, sans-serif;
                       font-size: 24px;
                       color: #ffffff;
                       text-align: left;
                       margin-bottom: 40px;
                       line-height: 1.5;
                    }}
    
                     .content-section {{
                       max-width: 900px;
                       margin: 0 auto;
                       text-align: left;
                       padding: 0 20px;
                     }}
    
                     .welcome-text {{
                       font-family: Arial, sans-serif;
                       font-size: 24px;
                       color: #ffffff;
                       text-align: left;
                       margin-bottom: 40px;
                       line-height: 1.5;
                     }}
    
                     .code-box {{
                       display: inline-block;
                       background-color: #00e573;
                       color: #ffffff;
                       font-family: 'Quantico', sans-serif;
                       font-size: 78px;
                       text-align: left;
                       padding: 20px 50px;
                       border-radius: 28px;
                       text-decoration: none;
                       box-shadow: 0px 0px 20px 0px rgba(139, 92, 246, 0.3);
                       margin: 30px 0;
                       transition: transform 0.2s;
                     }}
    
                     .code-box:hover {{
                       transform: scale(1.05);
                     }}
    
                     .disclaimer-text {{
                       font-family: Arial, sans-serif;
                       font-size: 24px;
                       color: #ffffff;
                       margin: 40px 0;
                       text-align:left;
                       line-height: 1.5;
                     }}
    
                     .divider {{
                       border: none;
                       border-top: 0.3px solid #999595;
                       margin: 60px 0 20px 0;
                     }}
    
                     .footer {{
                       font-family: Arial, sans-serif;
                       font-size: 24px;
                       color: #ffffff;
                       text-align: center;
                       margin-top: 30px;
                     }}
    
                     .footer .brand-footer {{
                       font-family: 'Quantico', sans-serif;
                     }}
    
                     /* Mobile responsive */
                     @media only screen and (max-width: 768px) {{
                       .brand-name {{
                         font-size: 48px;
                         margin-left: 0;
                         text-align: center;
                       }}
      
                        .display-name {{
                             font-size: 24px; 
                         }}
    
                       .code-box {{
                         font-size: 42px;
                         padding: 15px 35px;
                         display: block;
                         text-align: center;
                         margin: 30px auto;
                       }}
      
                       .welcome-text,
                       .disclaimer-text,
                       .footer {{
                         font-size: 16px;
                       }}
      
                       .logo-section {{
                         text-align: center;
                       }}
      
                       .logo {{
                         width: 150px;
                         height: 150px;
                         margin: 0 auto 20px;
                       }}
      
                       .content-section {{
                         text-align: left;
                       }}
                     }}
                   </style>
                   <!-- Google Fonts for Quantico -->
                   <link href=""https://fonts.googleapis.com/css2?family=Quantico:wght@400;700&display=swap"" rel=""stylesheet"">
                 </head>
                 <body>
                   <div class=""email-container"">
                     <!-- Logo Section -->
                     <div class=""logo"">
                       <img src=""cid:{contentId}"" alt=""KaZa Logo"" class=""logo"" />
                     </div>
    
                     <!-- Brand Name -->
                     <h1 class=""brand-name"">KazaBuild</h1>
    
                     <!-- Content Section -->
                     <div class=""content-section"">
                       <p class=""display-name"">
                         Hello, {displayName}
                       </p>
                       <p class=""welcome-text"">
                         Your login verification code is:
                       </p>
      
                       <!-- Code -->
                       <div class='code-box'>{code}</div>         

                       <!-- Disclaimer -->
                       <p class=""disclaimer-text"">
                        This code will expire in 10 minutes. Please do not share it with anyone.
                       </p>
                     </div>
    
                     <!-- Divider -->
                     <hr class=""divider"" />
    
                     <!-- Footer -->
                     <div class=""footer"">
                       <p>
                         <span>&copy; {DateTime.Now.Year} </span>
                         <span class=""brand-footer"">KAZABUILD</span>
                         <span>. All right reserved</span>
                       </p>
                     </div>
                   </div>
                 </body>
                 </html>";

            return new EmailContent
            {
                HtmlBody = body,
                ImagePath = imagePath,
                ContentId = contentId
            };
        }
    }
}
