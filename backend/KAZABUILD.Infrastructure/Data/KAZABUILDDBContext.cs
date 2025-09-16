using KAZABUILD.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Infrastructure.Data
{
    public class KAZABUILDDBContext : DbContext
    {
        public KAZABUILDDBContext(DbContextOptions<KAZABUILDDBContext> options) : base(options)
        {
        }

        //General tables
        public DbSet<Log> Logs { get; set; } = default!;

        //User related tables
        public DbSet<User> Users { get; set; } = default!;
        public DbSet<UserFollow> UserFollows { get; set; } = default!;
        public DbSet<UserToken> UserTokens { get; set; } = default!;

        //Declare enums and cascade delete behaviour
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            //====================================== USER ======================================//

            //Configure enums as strings
            modelBuilder
                .Entity<User>()
                .Property(u => u.UserRole)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.Theme)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.Language)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.ProfileAccessibility)
                .HasConversion<string>();

            //Unique index on email
            modelBuilder
                .Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            //Register address as a ValueObject
            modelBuilder.Entity<User>()
                .OwnsOne(u => u.Address);

            //====================================== USER FOLLOW ======================================//

            //Register relationships
            modelBuilder.Entity<UserFollow>()
                .HasOne(f => f.Follower)
                .WithMany(u => u.Followed)
                .HasForeignKey(f => f.FollowerId)
                .OnDelete(DeleteBehavior.NoAction); //Disable cascade delete when removing a follower

            modelBuilder.Entity<UserFollow>()
                .HasOne(f => f.Followed)
                .WithMany(u => u.Followers)
                .HasForeignKey(f => f.FollowedId)
                .OnDelete(DeleteBehavior.NoAction); //Disable cascade delete when removing a followed user

            //====================================== USER TOKEN ======================================//

            //Register relationship
            modelBuilder.Entity<UserToken>()
                .HasOne(f => f.User)
                .WithMany(u => u.UserTokens)
                .HasForeignKey(f => f.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
