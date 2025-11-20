using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RestrictDeleteBehaviourFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ForumPosts_Users_CreatorId",
                table: "ForumPosts");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Builds_BuildId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_ComponentReviews_ComponentReviewId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Components_ComponentId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_ForumPosts_ForumPostId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_UserComments_ParentCommentId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Users_UserId",
                table: "UserComments");

            migrationBuilder.AddForeignKey(
                name: "FK_ForumPosts_Users_CreatorId",
                table: "ForumPosts",
                column: "CreatorId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Builds_BuildId",
                table: "UserComments",
                column: "BuildId",
                principalTable: "Builds",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_ComponentReviews_ComponentReviewId",
                table: "UserComments",
                column: "ComponentReviewId",
                principalTable: "ComponentReviews",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Components_ComponentId",
                table: "UserComments",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_ForumPosts_ForumPostId",
                table: "UserComments",
                column: "ForumPostId",
                principalTable: "ForumPosts",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_UserComments_ParentCommentId",
                table: "UserComments",
                column: "ParentCommentId",
                principalTable: "UserComments",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Users_UserId",
                table: "UserComments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ForumPosts_Users_CreatorId",
                table: "ForumPosts");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Builds_BuildId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_ComponentReviews_ComponentReviewId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Components_ComponentId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_ForumPosts_ForumPostId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_UserComments_ParentCommentId",
                table: "UserComments");

            migrationBuilder.DropForeignKey(
                name: "FK_UserComments_Users_UserId",
                table: "UserComments");

            migrationBuilder.AddForeignKey(
                name: "FK_ForumPosts_Users_CreatorId",
                table: "ForumPosts",
                column: "CreatorId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Builds_BuildId",
                table: "UserComments",
                column: "BuildId",
                principalTable: "Builds",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_ComponentReviews_ComponentReviewId",
                table: "UserComments",
                column: "ComponentReviewId",
                principalTable: "ComponentReviews",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Components_ComponentId",
                table: "UserComments",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_ForumPosts_ForumPostId",
                table: "UserComments",
                column: "ForumPostId",
                principalTable: "ForumPosts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_UserComments_ParentCommentId",
                table: "UserComments",
                column: "ParentCommentId",
                principalTable: "UserComments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserComments_Users_UserId",
                table: "UserComments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
