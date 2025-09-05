using RabbitMQ.Client;

namespace KAZABUILD.Application.Interfaces
{
    public interface IRabbitMqConnection
    {
        Task<IConnection> GetConnectionAsync();
    }
}
