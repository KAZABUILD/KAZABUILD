using System.Diagnostics;
using System.Net.NetworkInformation;
using Microsoft.Extensions.Hosting;
using Prometheus;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Background service that periodically updates system metrics (CPU, Memory, Network).
    /// </summary>
    public class SystemMetricsService : BackgroundService
    {
        private static readonly Gauge CpuUsagePercent = Metrics
            .CreateGauge(
                "system_cpu_usage_percent",
                "Current CPU usage percentage (0-100)");

        private static readonly Gauge MemoryUsageBytes = Metrics
            .CreateGauge(
                "system_memory_usage_bytes",
                "Current memory usage in bytes");

        private static readonly Gauge MemoryUsagePercent = Metrics
            .CreateGauge(
                "system_memory_usage_percent",
                "Current memory usage percentage (0-100)");

        private static readonly Gauge MemoryAvailableBytes = Metrics
            .CreateGauge(
                "system_memory_available_bytes",
                "Available memory in bytes");

        private static readonly Counter NetworkBytesReceived = Metrics
            .CreateCounter(
                "system_network_bytes_received_total",
                "Total number of bytes received over the network");

        private static readonly Counter NetworkBytesSent = Metrics
            .CreateCounter(
                "system_network_bytes_sent_total",
                "Total number of bytes sent over the network");

        private static readonly Gauge NetworkBytesReceivedRate = Metrics
            .CreateGauge(
                "system_network_bytes_received_per_second",
                "Network bytes received per second");

        private static readonly Gauge NetworkBytesSentRate = Metrics
            .CreateGauge(
                "system_network_bytes_sent_per_second",
                "Network bytes sent per second");

        private readonly TimeSpan _updateInterval = TimeSpan.FromSeconds(1);
        private Process? _currentProcess;
        private DateTime _lastCpuUpdate;
        private TimeSpan _lastCpuTime;
        private long _lastNetworkBytesReceived;
        private long _lastNetworkBytesSent;
        private DateTime _lastNetworkUpdate;

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                _currentProcess = Process.GetCurrentProcess();
                _currentProcess.Refresh();
                _lastCpuUpdate = DateTime.UtcNow;
                _lastCpuTime = _currentProcess.TotalProcessorTime;
                _lastNetworkUpdate = DateTime.UtcNow;
                _lastNetworkBytesReceived = GetTotalBytesReceived();
                _lastNetworkBytesSent = GetTotalBytesSent();

                while (!stoppingToken.IsCancellationRequested)
                {
                    await UpdateMetricsAsync();
                    await Task.Delay(_updateInterval, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                // Log error but don't crash the service
                Console.WriteLine($"Error in SystemMetricsService: {ex.Message}");
            }
        }

        private async Task UpdateMetricsAsync()
        {
            try
            {
                // Update CPU metrics
                UpdateCpuMetrics();

                // Update Memory metrics
                UpdateMemoryMetrics();

                // Update Network metrics
                await UpdateNetworkMetricsAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating metrics: {ex.Message}");
            }
        }

        private void UpdateCpuMetrics()
        {
            try
            {
                if (_currentProcess != null)
                {
                    _currentProcess.Refresh();
                    var now = DateTime.UtcNow;
                    var currentCpuTime = _currentProcess.TotalProcessorTime;
                    
                    // Calculate CPU usage percentage based on process time delta
                    var timeDelta = (now - _lastCpuUpdate).TotalMilliseconds;
                    if (timeDelta > 0)
                    {
                        var cpuTimeDelta = (currentCpuTime - _lastCpuTime).TotalMilliseconds;
                        // CPU percentage = (CPU time used / real time elapsed) * 100
                        // This gives percentage of one CPU core. For multi-core systems,
                        // this can exceed 100% if the process uses multiple cores.
                        var cpuPercent = Math.Min(100.0 * Environment.ProcessorCount, (cpuTimeDelta / timeDelta) * 100.0);
                        CpuUsagePercent.Set(cpuPercent);
                    }
                    
                    _lastCpuUpdate = now;
                    _lastCpuTime = currentCpuTime;
                }
            }
            catch
            {
                // If CPU metrics can't be collected, set to 0
                CpuUsagePercent.Set(0);
            }
        }

        private void UpdateMemoryMetrics()
        {
            try
            {
                if (_currentProcess != null)
                {
                    _currentProcess.Refresh();

                    // Process memory usage
                    var workingSet = _currentProcess.WorkingSet64;
                    MemoryUsageBytes.Set(workingSet);

                    // Try to get system-wide memory info (works on Linux, may not work on Windows)
                    try
                    {
                        var totalMemory = GC.GetTotalMemory(false);
                        var memoryInfo = GetSystemMemoryInfo();
                        
                        if (memoryInfo.TotalBytes > 0)
                        {
                            var memoryPercent = (double)memoryInfo.UsedBytes / memoryInfo.TotalBytes * 100.0;
                            MemoryUsagePercent.Set(memoryPercent);
                            MemoryAvailableBytes.Set(memoryInfo.AvailableBytes);
                        }
                    }
                    catch
                    {
                        // Fallback: Use process memory as percentage estimate
                        // This is not accurate but provides some visibility
                    }
                }
            }
            catch
            {
                // If memory metrics can't be collected, set to 0
                MemoryUsageBytes.Set(0);
            }
        }

        private async Task UpdateNetworkMetricsAsync()
        {
            try
            {
                var now = DateTime.UtcNow;
                var currentBytesReceived = GetTotalBytesReceived();
                var currentBytesSent = GetTotalBytesSent();

                // Calculate bytes since last update
                var bytesReceivedDelta = currentBytesReceived - _lastNetworkBytesReceived;
                var bytesSentDelta = currentBytesSent - _lastNetworkBytesSent;
                var timeDelta = (now - _lastNetworkUpdate).TotalSeconds;

                if (timeDelta > 0)
                {
                    // Update total counters
                    NetworkBytesReceived.Inc(bytesReceivedDelta);
                    NetworkBytesSent.Inc(bytesSentDelta);

                    // Calculate and set rates (bytes per second)
                    var receivedRate = bytesReceivedDelta / timeDelta;
                    var sentRate = bytesSentDelta / timeDelta;

                    NetworkBytesReceivedRate.Set(receivedRate);
                    NetworkBytesSentRate.Set(sentRate);
                }

                _lastNetworkBytesReceived = currentBytesReceived;
                _lastNetworkBytesSent = currentBytesSent;
                _lastNetworkUpdate = now;
            }
            catch
            {
                // If network metrics can't be collected, set rates to 0
                NetworkBytesReceivedRate.Set(0);
                NetworkBytesSentRate.Set(0);
            }
        }

        private long GetTotalBytesReceived()
        {
            try
            {
                return NetworkInterface.GetAllNetworkInterfaces()
                    .Where(ni => ni.OperationalStatus == OperationalStatus.Up && 
                                 ni.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                    .Sum(ni => ni.GetIPStatistics().BytesReceived);
            }
            catch
            {
                return 0;
            }
        }

        private long GetTotalBytesSent()
        {
            try
            {
                return NetworkInterface.GetAllNetworkInterfaces()
                    .Where(ni => ni.OperationalStatus == OperationalStatus.Up && 
                                 ni.NetworkInterfaceType != NetworkInterfaceType.Loopback)
                    .Sum(ni => ni.GetIPStatistics().BytesSent);
            }
            catch
            {
                return 0;
            }
        }

        private (long TotalBytes, long UsedBytes, long AvailableBytes) GetSystemMemoryInfo()
        {
            try
            {
                // Try to read /proc/meminfo on Linux
                if (File.Exists("/proc/meminfo"))
                {
                    var memInfo = File.ReadAllLines("/proc/meminfo");
                    long memTotal = 0;
                    long memAvailable = 0;

                    foreach (var line in memInfo)
                    {
                        if (line.StartsWith("MemTotal:"))
                        {
                            memTotal = ParseMemInfoLine(line);
                        }
                        else if (line.StartsWith("MemAvailable:"))
                        {
                            memAvailable = ParseMemInfoLine(line);
                        }
                    }

                    if (memTotal > 0)
                    {
                        var used = memTotal - memAvailable;
                        return (memTotal * 1024, used * 1024, memAvailable * 1024); // Convert KB to bytes
                    }
                }
            }
            catch
            {
                // Fallback if /proc/meminfo is not available
            }

            return (0, 0, 0);
        }

        private long ParseMemInfoLine(string line)
        {
            var parts = line.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length >= 2 && long.TryParse(parts[1], out var value))
            {
                return value;
            }
            return 0;
        }

        public override void Dispose()
        {
            _currentProcess?.Dispose();
            base.Dispose();
        }
    }
}

