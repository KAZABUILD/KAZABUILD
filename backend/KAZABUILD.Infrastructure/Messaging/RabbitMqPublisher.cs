using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Enums;

using Microsoft.Extensions.DependencyInjection;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace KAZABUILD.Infrastructure.Messaging
{
    //Publishes messages to RabbitMQ queue
    public class RabbitMQPublisher(IRabbitMqConnection connection, IServiceProvider serviceProvider) : IRabbitMQPublisher
    {
        //Variable which stores the connection to rabbitMQ
        private readonly IRabbitMqConnection _connection = connection;

        //Variable storing the service provider required to use the logger
        private readonly IServiceProvider _serviceProvider = serviceProvider;

        //Function that publishes requests to the queue
        public async Task PublishAsync<T>(string queueName, T message)
        {
            //Declare variable necessary to store the rabbitMQ channel to close it later
            IChannel? channel = null;

            try
            {
                //Get the connection
                IConnection? connection = await _connection.GetConnectionAsync().ConfigureAwait(false);

                //Get the channel for the connection
                channel = await connection.CreateChannelAsync().ConfigureAwait(false);

                //Get the RabbitMQ queue
                await channel.QueueDeclareAsync(queue: queueName, durable: false, exclusive: false, autoDelete: false).ConfigureAwait(false);

                //Create the body in the proper format from the message
                var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

                //Publish the message
                await channel.BasicPublishAsync(exchange: "", routingKey: queueName, body: body).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                //Create the scope and get the logger
                using var scope = _serviceProvider.CreateScope();
                var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

                //Log the service failure
                await logger.LogAsync(
                    Guid.Empty,
                    "Publisher",
                    "RabbitMQ",
                    "",
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    $"RabbitMQ Unavailable. Skipping publishing. Error message: {ex.Message}"
                );
            }
            finally
            {
                //Graceful shutdown
                if (channel is not null)
                {
                    try { await channel.CloseAsync(); } catch { }
                    channel.Dispose();
                }
            }
        }
    }
}
