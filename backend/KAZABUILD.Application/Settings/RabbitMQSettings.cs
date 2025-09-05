using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class RabbitMQSettings
    {
        [Required]
        public string Host { get; set; } = "localhost";

        public int Port { get; set; } = 5672;

        public string Username { get; set; } = "guest";

        public string Password { get; set; } = "guest";

        public string QueueName { get; set; } = "defaultQueue";

        public ushort PrefetchCount { get; set; } = 10;
    }
}
