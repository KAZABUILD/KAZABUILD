using KAZABUILD.Application.Interfaces;

using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace KAZABUILD.Infrastructure.Messaging
{
    //Publishes messages to RabbitMQ queue
    public class RabbitMQPublisher(IRabbitMqConnection connection) : IRabbitMQPublisher
    {
        private readonly IRabbitMqConnection _connection = connection;

        public async Task PublishAsync<T>(string queueName, T message)
        {
            //Get the connection
            IConnection? connection = await _connection.GetConnectionAsync().ConfigureAwait(false);

            //Get the channel for the connection
            await using IChannel? channel = await connection.CreateChannelAsync().ConfigureAwait(false);

            //Get the RabbitMQ queue
            await channel.QueueDeclareAsync(queue: queueName, durable: false, exclusive: false, autoDelete: false).ConfigureAwait(false);

            //Create the body in the proper format from the message
            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

            //Publish the message
            await channel.BasicPublishAsync(exchange: "", routingKey: queueName, body: body).ConfigureAwait(false);
        }
    }
}
