using KAZABUILD.Application.Interfaces;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace KAZABUILD.Application.Health
{
    public class RabbitMQHealthCheck(IRabbitMqConnection conn) : IHealthCheck
    {
        private readonly IRabbitMqConnection _conn = conn;

        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct = default)
        {
            //Try to establish a connection, return if it failed or not
            try
            {
                var connection = await _conn.GetConnectionAsync();
                if (connection.IsOpen) return HealthCheckResult.Healthy("RabbitMQ open");
                return HealthCheckResult.Unhealthy("RabbitMQ not open");
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Unhealthy("RabbitMQ exception", ex);
            }
        }
    }
}
