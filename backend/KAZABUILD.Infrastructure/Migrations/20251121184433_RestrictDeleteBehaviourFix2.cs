using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RestrictDeleteBehaviourFix2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_BuildComponents_Components_ComponentId",
                table: "BuildComponents");

            migrationBuilder.DropForeignKey(
                name: "FK_UserActivities_Users_UserId",
                table: "UserActivities");

            migrationBuilder.DropForeignKey(
                name: "FK_UserCommentInteractions_UserComments_UserCommentId",
                table: "UserCommentInteractions");

            migrationBuilder.DropForeignKey(
                name: "FK_UserFeedback_Users_UserId",
                table: "UserFeedback");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserFeedback",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserCommentId",
                table: "UserCommentInteractions",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserActivities",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AlterColumn<Guid>(
                name: "BuildId",
                table: "BuildInteractions",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddForeignKey(
                name: "FK_BuildComponents_Components_ComponentId",
                table: "BuildComponents",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserActivities_Users_UserId",
                table: "UserActivities",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserCommentInteractions_UserComments_UserCommentId",
                table: "UserCommentInteractions",
                column: "UserCommentId",
                principalTable: "UserComments",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_UserFeedback_Users_UserId",
                table: "UserFeedback",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_BuildComponents_Components_ComponentId",
                table: "BuildComponents");

            migrationBuilder.DropForeignKey(
                name: "FK_UserActivities_Users_UserId",
                table: "UserActivities");

            migrationBuilder.DropForeignKey(
                name: "FK_UserCommentInteractions_UserComments_UserCommentId",
                table: "UserCommentInteractions");

            migrationBuilder.DropForeignKey(
                name: "FK_UserFeedback_Users_UserId",
                table: "UserFeedback");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserFeedback",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserCommentId",
                table: "UserCommentInteractions",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserActivities",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "BuildId",
                table: "BuildInteractions",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_BuildComponents_Components_ComponentId",
                table: "BuildComponents",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserActivities_Users_UserId",
                table: "UserActivities",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserCommentInteractions_UserComments_UserCommentId",
                table: "UserCommentInteractions",
                column: "UserCommentId",
                principalTable: "UserComments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserFeedback_Users_UserId",
                table: "UserFeedback",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
