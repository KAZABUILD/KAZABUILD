using KAZABUILD.Application.Helpers;
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
        public DbSet<UserPreference> UserPreferences { get; set; } = default!;
        public DbSet<UserFollow> UserFollows { get; set; } = default!;
        public DbSet<UserToken> UserTokens { get; set; } = default!;
        public DbSet<UserComment> UserComments { get; set; } = default!;
        public DbSet<ForumPost> ForumPosts { get; set; } = default!;
        public DbSet<Message> Messages { get; set; } = default!;
        public DbSet<Notification> Notifications { get; set; } = default!;

        //Declare enums and cascade delete behaviour
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            //Register the db full-text search function
            modelBuilder
                .HasDbFunction(() => FullTextDbFunction.Contains(default!, default!))
                .HasName("CONTAINS");

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

            //Unique index on login
            modelBuilder
                .Entity<User>()
                .HasIndex(u => u.Login)
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
                .OnDelete(DeleteBehavior.NoAction); //Disable cascade delete when removing a follower, must be handled in API calls

            modelBuilder.Entity<UserFollow>()
                .HasOne(f => f.Followed)
                .WithMany(u => u.Followers)
                .HasForeignKey(f => f.FollowedId)
                .OnDelete(DeleteBehavior.NoAction); //Disable cascade delete when removing a followed user, must be handled in API calls

            //====================================== USER TOKEN ======================================//

            //Configure TokenType enum as string
            modelBuilder
                .Entity<UserToken>()
                .Property(u => u.TokenType)
                .HasConversion<string>();

            //Register relationship with user
            modelBuilder.Entity<UserToken>()
                .HasOne(t => t.User)
                .WithMany(u => u.UserTokens)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== USER PREFERENCE ======================================//

            //Register relationship with user
            modelBuilder.Entity<UserPreference>()
                .HasOne(p => p.User)
                .WithMany(u => u.UserPreferences)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== USER COMMENT ======================================//

            //Configure CommentTargetType enum as string
            modelBuilder
                .Entity<UserComment>()
                .Property(u => u.CommentTargetType)
                .HasConversion<string>();

            //Register relationships
            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.User)
                .WithMany(u => u.UserComments)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.ForumPost)
                .WithMany(u => u.UserComments)
                .HasForeignKey(c => c.ForumPostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.ParentComment)
                .WithMany(pc => pc.ChildComments)
                .HasForeignKey(c => c.ParentCommentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== FORUM POST ======================================//

            //Register relationship with user
            modelBuilder.Entity<ForumPost>()
                .HasOne(p => p.Creator)
                .WithMany(u => u.ForumPosts)
                .HasForeignKey(p => p.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== MESSAGE ======================================//

            //Configure MessageType enum as string
            modelBuilder
                .Entity<Message>()
                .Property(u => u.MessageType)
                .HasConversion<string>();

            //Register relationships, deleting messages should be handles in API calls
            modelBuilder.Entity<Message>()
                .HasOne(m => m.Sender)
                .WithMany(u => u.SentMessages)
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Receiver)
                .WithMany(u => u.ReceivedMessages)
                .HasForeignKey(m => m.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.ParentMessage)
                .WithMany(pm => pm.ChildMessages)
                .HasForeignKey(m => m.ParentMessageId)
                .OnDelete(DeleteBehavior.NoAction);

            //====================================== NOTFICATION ======================================//

            //Configure NotificationType enum as string
            modelBuilder
                .Entity<Notification>()
                .Property(u => u.NotificationType)
                .HasConversion<string>();

            //Register relationship with user
            modelBuilder.Entity<Notification>()
                .HasOne(m => m.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(m => m.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
