# List of issues found in the code

## EXAMPLE

[00000] Bug description.
- Type: incorrect implementation/error/missing feature
- Status: fixed/edited/pending
- Source: backend/frontend/database/testing
- Details: Write details if necessary.

## BUGS

[00001] The 3d model loads before the loading screen.
- Type: error
- Status: pending
- Source: frontend

[00002] The build loading takes forever.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: Tags are getting queried one by one causing the application to not load within a reasonable time frame.

[00003] The FAQ section is written incorrectly.
- Type: incorrect implementation
- Status: pending
- Source: frontend
- Details: The section has to be written by a human and adjusted for actual content of the website. The section should include questions which are actually relevant. The sections should be present on its own page instead of the - main page.

[00004] Reloading the website taken a long time and takes the user to the main page.
- Type: error
- Status: FIXED
- Source: frontend

[00005] User cannot open any link in a new card in the browser.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: The user should have the option to easily open any link on the website on another card.

[00006] About us section is missing pictures and the navigation bar.
- Type: error/missing feature
- Status: FIXED
- Source: frontend

[00007] The 3d model display allows user interaction.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: The 3d model should be immutable.

[00008] Similar builds are getting cut off on build pages.
- Type: error
- Status: FIXED
- Source: frontend

[00009] The add new comment box should be on top of a comment section.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00010] The dark color scheme is difficult to read in many parts of the website.
- Type: incorrect implementation
- Status: pending
- Source: frontend

[00011] The designs on the website and figma do not match.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00012] The user cannot interact with components on the build page.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00013] The "Follow Build" button shouldn't be present in the build page.
- Type: incorrect implementation/error
- Status: FIXED
- Source: frontend
- Details: There is no such feature as following builds in the buildInteraction model.

[00014] Changing the language doesn't change the text on the builds page.
- Type: incorrect implementation/error
- Status: FIXED
- Source: frontend

[00015] The default image is incorrect.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: Default images should not have any text in them and should scale to the size of the displayed image.

[00016] The forum post loading takes forever.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: Comments are getting queried one by one causing the application to not load within a reasonable time frame.

[00017] Paging is done client side only.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: The website should be paging server side.

[00018] The system admin is not using the name set in the appsettings.
- Type: error
- Status: FIXED
- Source: backend

[00019] The user doesn't have the option to see notifications and send messages on the navigation bar.
- Type: missing feature
- Status: FIXED
- Source: frontend

[00020] The website freezes whenever there are a lot of elements loaded.
- Type: error
- Status: pending
- Source: frontend

[00021] The admin page editing and viewing are broken.
- Type: incorrect implementation/error/missing feature
- Status: FIXED
- Source: frontend
- Details: The editing button doesn't do anything, while the view button takes the user to an incorrect URL.

[00022] The admin should be able to modify their profile only like the normal user would.
- Type: incorrect implementation
- Status: INCORRECT
- Source: frontend
- Details: The settings from the admin page should be removed/reworked.

[00023] Attempting to get tags with a query results in the failure.
- Type: incorrect implementation/error/missing feature
- Status: FIXED
- Source: backend
- Details: Error code: "Microsoft.Data.SqlClient.SqlException: 'An expression of non-boolean type specified in a context where a condition is expected, near 'OR'.'".

[00024] Attempting to post or save the build freezes the website.
- Type: incorrect implementation/error
- Status: FIXED
- Source: frontend
- Details: The application needs a performance increase.

[00025] The content displayed on webpages should differ based on the user id and access level.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: For example, if the user is viewing their own profile they should see options to modify it vs other users should see an additional follow button.

[00025-A] The user should be able to modify their builds.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: The option is missing from build page.

[00026] The build page does not display who created the build.
- Type: incorrect implementation/error/missing feature
- Status: FIXED
- Source: frontend

[00027] The errors displayed to the users shouldn't contain error output.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: User readable errors either should have simplified output or no output displayed at all.

[00028] The explore builds page search doesn't use server side paging.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: Any paging for a lot of elements should be paginated. ordered and searched using the server.

[00029] The builds in the explore build page shouldn't have "click to view" text when the entire object is clickable.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00030] Explore builds rating is missing.
- Type: missing feature
- Status: fixed
- Source: frontend

[00031] Incorrect frontend output.
- Type: error
- Status: pending
- Source: frontend
- Details: The way performance is displayed for CPU parts is too long when displayed as a float.

[00007-A] The 3d model display still allows user interaction - the bug was not fixed.
- Type: error
- Status: FIXED
- Source: frontend
- Details: The 3d model should be immutable.

[00032] Price is not loaded for the components correctly.
- Type: incorrect implementation/error/missing feature
- Status: FIXED
- Source: frontend
- Details: There can be several prices for a components so the lowest one should be chosen (or some other metric).

[00033] Explore builds and build pages takes around 10 seconds to load.
- Type: error
- Status: FIXED
- Source: frontend

[00005-A] User cannot open any link in a new card in the browser - the bug was not fixed.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: The user should have the option to easily open any link on the website on another card. When right clicking an element on the website it should display an option to open in new card, when middle clicking it should open in a new card.

[00006-A] About us section is missing team member pictures.
- Type: missing feature
- Status: pending
- Source: frontend

[00034] The default image is not loading in the explore builds sections and the build pages.
- Type: error
- Status: pending
- Source: frontend

[00035] The forum posts sorting by categories doesn't work.
- Type: error
- Status: FIXED
- Source: frontend
- Details: Error loading posts message appears despite the posts loading in the "all" category. The error seems to disappear after a while but it should not appear at all.

[00036] Paging should be applied for users when sending new messages.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: There should be a limited number of users displayed.

[00037] The user should be able to attach images to Users/Forum Posts/Comments/Builds.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: Additionally an admin should be able to attach images to Components/SubComponents.

[00038] Admins should be able to send notifications from the admin panel.
- Type: missing feature
- Status: pending
- Source: frontend
- Details: The admin should be able to specify what kind of users will receive the notification.

[00038] The admin should be able to plan future notifications for users through setting the send date to the future.
- Type: incorrect implementation/error/missing feature
- Status: pending
- Source: backend/frontend
- Details: The backend should only return notification based on whether the data passed or not, the frontend should allow the admins to choose the date. This feature will be necessary for sending promotional notifs later on.

[00039] No paging in the admin panel.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00021-A] The admin page editing and viewing are broken - not fully fixed.
- Type: incorrect implementation/missing feature
- Status: FIXED
- Source: frontend
- Details: The components editing is not implemented yet. Posts cannot be edited

[00040] Posted comments don't appear until the webpage is refreshed.
- Type: incorrect implementation/error
- Status: FIXED
- Source: frontend

[00041] The user cannot reply to a comment.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: The user should be able to choose a comment they are replying to using "ParentCommentId" in the comment model.

[00042] Administrators receive an unauthorized access notice for editing.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend
- Details: Administrators should be able to edit anything, while moderators should be able to modify user related parts of the website (comments/user profiles/etc).

[00043] The administrators and moderators should be able to assign user roles.
- Type: missing feature
- Status: FIXED
- Source: frontend
- Details: Assigning roles should function normally except for bans which should allow the staff to assigned the bannedUntil value.

[00044] The UserGuide model is missing.
- Type: missing feature
- Status: pending
- Source: backend

[00045] There are no filters in the explore builds page.
- Type: missing feature
- Status: pending
- Source: frontend

[00027-A] The errors displayed to the users shouldn't contain error output - bug not fully fixed.
- Type: incorrect implementation
- Status: pending 
- Source: frontend
- Details: User readable errors either should have simplified output or no output displayed at all. Example - the error for when the connection to the server fails.

[00046] The filters in the parts webpage should be a dropdown for accessibility.
- Type: incorrect implementation
- Status: FIXED
- Source: frontend

[00047] Add limit for the images and gifs per components.
- Type: missing feature
- Status: FIXED
- Source: backend

[00048] SQL Foreign Key Conflict (FK_UserComments_UserComments_ParentCommentId) prevents deletion of Builds/ForumPosts
- Type: incorrect implementation
- Status: FIXED
- Source: backend / database
- Details: The Error: When attempting to delete a Build or Forum Post via the Admin Panel, the operation fails with the following SQL exception: The DELETE statement conflicted with the SAME TABLE REFERENCE constraint "FK_UserComments_UserComments_ParentCommentId". The conflict occurred in database "KAZABUILD_DB", table "dbo.UserComments", column 'ParentCommentId'.

[00049] User Deletion Fails due to Linked Forum Posts & Comments.
- Type: incorrect implementation
- Status: FIXED
- Source: backend / database
- Details: The Error: When attempting to delete a User, the operation fails with: The DELETE statement conflicted with the REFERENCE constraint "FK_UserComments_ForumPosts_ForumPostId". Root Cause: When a User is deleted, the system attempts to cascade delete the Forum Posts created by that user. However, the database blocks the deletion of the Forum Post because there are UserComments attached to that post. The deletion chain breaks at: User -> ForumPost -> [BLOCKED] -> UserComments.

[00050] Introduce an additional column in every model that has a nullable foreign key to store the key in case of deletion.
- Type: incorrect implementation
- Status: pending
- Source: backend
- Details: This will enable preservation of deleted users for message chats and similar situations.

[00051] Token Lookup query failing when
- Type: missing implementation
- status: INCORRECT
- Source: backend
- Details: Token verification now fetches all unused tokens of the given type from the database into memory, then verifies client-supplied tokens against them, instead of filtering by `UserId` first. This allows an attacker to use any valid token hash from any user by providing it as a token. The original query filtered by both `UserId` and token hash server-side. This must check `t.UserId` against the DTO's user ID before verification.

[00052] SentAtStart filter failing in both MessagesController and NotifcationsController.
- Type: incorrect implementation
- Status: FIXED
- Source: backend
- Details: When filtering by `SentAtStart`, the query uses `dto.SentAtEnd` instead of `dto.SentAtStart`, causing date range filters to malfunction. Users filtering by start date will get incorrect results. This should compare against `dto.SentAtStart`.

[00053] UserAnswerController checks wrong table for preference answer.
- Type: incorrect implementation
- Status: FIXED
- Source: backend
- Details: When validating that a `UserPreferenceAnswer` exists, the code queries `_db.Users` instead of the correct table (`_db.UserPreferenceAnswers`). This will always fail to find the preference answer, causing all user answer creation attempts to fail with "Answer not found!" error.
