using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class BuildDomainsIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            //Add indexes on Build Domain tables
            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Builds'))
                    CREATE FULLTEXT INDEX ON Builds(Name LANGUAGE 0, Description LANGUAGE 0)
                    KEY INDEX PK_Builds;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.BuildInteractions'))
                    CREATE FULLTEXT INDEX ON BuildInteractions(UserNote LANGUAGE 0)
                    KEY INDEX PK_BuildInteractions;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Tags'))
                    CREATE FULLTEXT INDEX ON Tags(Name LANGUAGE 0, Description LANGUAGE 0)
                    KEY INDEX PK_Tags;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserComments'))
                    CREATE FULLTEXT INDEX ON UserComments(Content LANGUAGE 0)
                    KEY INDEX PK_UserComments;",
                suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            //Drop Indexes on Build Domain tables
            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Builds;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON BuildInteractions;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Tags;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserComments;", suppressTransaction: true);
        }
    }
}
