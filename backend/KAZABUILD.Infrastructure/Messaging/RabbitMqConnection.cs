using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;


namespace KAZABUILD.Infrastructure.Messaging
{
    /// <summary>
    /// Creates and caches a singular connection from RabbitMQ.
    /// </summary>
    /// <param name="settings"></param>
    public class RabbitMQConnection(IOptions<RabbitMQSettings> settings) : IRabbitMqConnection
    {
        private readonly RabbitMQSettings _settings = settings.Value;
        private Task<IConnection>? _connectionTask;

        /// <summary>
        /// Function that creates the connection.
        /// </summary>
        /// <returns></returns>
        public Task<IConnection> GetConnectionAsync()
        {
            //If the connection in not set already build a new connection from config
            if (_connectionTask == null)
            {
                var factory = new ConnectionFactory
                {
                    HostName = _settings.Host,
                    Port = _settings.Port,
                    UserName = _settings.Username,
                    Password = _settings.Password
                };
                _connectionTask = factory.CreateConnectionAsync();
            }

            return _connectionTask;
        }
    }
}
