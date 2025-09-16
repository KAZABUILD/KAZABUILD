using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using ILoggerService = KAZABUILD.Application.Interfaces.ILoggerService;

namespace KAZABUILD.Infrastructure.Messaging
{
    public class RabbitMQConsumer(IRabbitMqConnection connection, IOptions<RabbitMQSettings> settings, IServiceProvider serviceProvider) : BackgroundService
    {
        private readonly IRabbitMqConnection _connection = connection;
        private readonly RabbitMQSettings _settings = settings.Value;
        private readonly IServiceProvider _serviceProvider = serviceProvider;

        //Background service that consumes the requests from the queue
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            //Declare variables to store the rabbitMQ connection
            IConnection? connection = null;
            IChannel? channel = null;

            try
            {
                //Get the connection
                connection = await _connection.GetConnectionAsync().ConfigureAwait(false);

                //Create a new channel for the connection
                channel = await connection.CreateChannelAsync(cancellationToken: stoppingToken).ConfigureAwait(false);

                //Fair dispatch / QoS
                await channel.BasicQosAsync(0, _settings.PrefetchCount, global: false, stoppingToken);

                //Get the RabbitMQ queue
                await channel.QueueDeclareAsync(queue: "defaultQueue", durable: false, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);

                //Get the consumer
                var consumer = new AsyncEventingBasicConsumer(channel);

                //Handle the received events
                consumer.ReceivedAsync += async (model, ea) =>
                {
                    try
                    {
                        //Deserialize event body to a dynamic object
                        var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                        var payload = JsonSerializer.Deserialize<Dictionary<string, object>>(json);

                        //TODO: add processing logic

                        //Acknoledge and removed message from queue
                        await channel.BasicAckAsync(ea.DeliveryTag, multiple: false);
                    }
                    catch
                    {
                        //Negatively acknowledge and requeue
                        await channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: true);
                    }
                };

                //Start consuming
                await channel.BasicConsumeAsync(queue: _settings.QueueName ?? "defaultQueue", autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

                //Keep the background service alive until stopped
                //Wait here until cancellation is requested
                await Task.Delay(Timeout.Infinite, stoppingToken);
            }
            catch (Exception ex)
            {
                using var scope = _serviceProvider.CreateScope();
                var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

                await logger.LogAsync(
                    Guid.Empty,
                    "RabbitMQ",
                    "Consumer",
                    "",
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"RabbitMQ Unavailable. Skipping consumer startup. Error message: {ex.Message}"
                );
            }
            finally
            {
                //Graceful shutdown
                if (channel is not null)
                {
                    try { await channel.CloseAsync(cancellationToken: stoppingToken); } catch { }
                    channel.Dispose();
                }

            }

        }
    }
}
