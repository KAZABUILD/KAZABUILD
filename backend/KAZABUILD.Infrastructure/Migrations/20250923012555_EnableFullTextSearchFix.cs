using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class EnableFullTextSearchFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            //Create a catalog for full-text search
            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = 'KazabuildCatalog')
                    CREATE FULLTEXT CATALOG KazabuildCatalog AS DEFAULT;
            ", suppressTransaction: true);

            //Add a full-text index for each searchable table
            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Users'))
                    CREATE FULLTEXT INDEX ON Users(DisplayName LANGUAGE 0, Login LANGUAGE 0, Email LANGUAGE 0, Description LANGUAGE 0, Location LANGUAGE 0)
                    KEY INDEX PK_Users;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserComments'))
                    CREATE FULLTEXT INDEX ON UserComments(Content LANGUAGE 0)
                    KEY INDEX PK_UserComments;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Notifications'))
                    CREATE FULLTEXT INDEX ON Notifications(Body LANGUAGE 0, Title LANGUAGE 0, LinkUrl LANGUAGE 0)
                    KEY INDEX PK_Notifications;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Messages'))
                    CREATE FULLTEXT INDEX ON Messages(Content LANGUAGE 0, Title LANGUAGE 0)
                    KEY INDEX PK_Messages;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Logs'))
                    CREATE FULLTEXT INDEX ON Logs(ActivityType LANGUAGE 0, TargetType LANGUAGE 0, Description LANGUAGE 0, IpAddress LANGUAGE 0)
                    KEY INDEX PK_Logs;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
            IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.ForumPosts'))
                    CREATE FULLTEXT INDEX ON ForumPosts(Content LANGUAGE 0, Title LANGUAGE 0, Topic LANGUAGE 0)
                    KEY INDEX PK_ForumPosts;
            ", suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            //Remove indexes for full-text search
            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Users;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserComments;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Notifications;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Messages;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Logs;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ForumPosts;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT CATALOG KazabuildCatalog;", suppressTransaction: true);
        }
    }
}
