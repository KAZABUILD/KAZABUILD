namespace KAZABUILD.Application.Interfaces
{
    public interface IRabbitMQPublisher
    {
        Task PublishAsync<T>(string queueName, T message);
    }
}
