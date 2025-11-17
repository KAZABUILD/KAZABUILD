# Additional Metrics Suggestions for KAZABUILD

This document provides suggestions for additional metrics that would be valuable to monitor for the KAZABUILD project.

## Currently Implemented Metrics

### System Metrics
- ✅ CPU Usage Percentage
- ✅ Memory Usage (bytes and percentage)
- ✅ Network Traffic (bytes sent/received, rates)

### Application Metrics
- ✅ HTTP Request Rate
- ✅ HTTP Request Duration (p50, p95, p99)
- ✅ Non-Information Logs Rate
- ✅ Banned Users Count
- ✅ Emails Sent/Failed

## Recommended Additional Metrics

### 1. Database Metrics
**Why:** Monitor database performance and connection health

- **Database Connection Pool Usage**
  - Active connections
  - Idle connections
  - Connection wait time
  - Query: `efcore_connection_pool_active_connections`, `efcore_connection_pool_idle_connections`

- **Database Query Performance**
  - Average query duration
  - Slow query count (>1s, >5s thresholds)
  - Query: `efcore_query_duration_seconds`, `efcore_queries_slow_total`

- **Database Transaction Metrics**
  - Active transactions
  - Transaction duration
  - Rollback rate
  - Query: `efcore_transactions_active`, `efcore_transaction_duration_seconds`

### 2. RabbitMQ Metrics
**Why:** Monitor message queue health and throughput

- **Queue Depth**
  - Messages in queue
  - Queue size over time
  - Query: `rabbitmq_queue_messages`, `rabbitmq_queue_messages_ready`

- **Message Processing Rate**
  - Messages consumed per second
  - Messages published per second
  - Query: `rabbitmq_messages_consumed_total`, `rabbitmq_messages_published_total`

- **Consumer Lag**
  - Time between message publish and consume
  - Query: `rabbitmq_consumer_lag_seconds`

- **Connection Health**
  - Active connections
  - Connection failures
  - Query: `rabbitmq_connections_active`, `rabbitmq_connection_failures_total`

### 3. Authentication & Security Metrics
**Why:** Monitor security events and authentication patterns

- **Authentication Attempts**
  - Successful logins
  - Failed login attempts
  - Login rate by method (JWT, Google OAuth)
  - Query: `auth_login_success_total`, `auth_login_failure_total`

- **Token Metrics**
  - Active tokens
  - Token expiration rate
  - Token refresh rate
  - Query: `auth_tokens_active`, `auth_tokens_expired_total`, `auth_tokens_refreshed_total`

- **Rate Limiting Events**
  - Requests rate-limited
  - Rate limit violations by endpoint
  - Query: `rate_limit_hits_total`, `rate_limit_violations_total`

- **IP Blocking Events**
  - IPs blocked per hour/day
  - Block duration distribution
  - Query: `security_ips_blocked_total`, `security_block_duration_seconds`

### 4. Business Logic Metrics
**Why:** Monitor application-specific functionality

- **User Activity**
  - Active users (last 5/15/30 minutes)
  - New user registrations
  - User profile updates
  - Query: `users_active_total`, `users_registered_total`, `users_profile_updates_total`

- **Build Operations**
  - Builds created
  - Builds completed
  - Build duration
  - Build failures
  - Query: `builds_created_total`, `builds_completed_total`, `build_duration_seconds`, `builds_failed_total`

- **Component Operations**
  - Components created
  - Components viewed
  - Component search queries
  - Query: `components_created_total`, `components_viewed_total`, `component_searches_total`

- **Image Operations**
  - Images uploaded
  - Images served
  - Image processing time
  - Query: `images_uploaded_total`, `images_served_total`, `image_processing_duration_seconds`

### 5. Cache Metrics
**Why:** Monitor cache effectiveness and performance

- **Cache Hit/Miss Ratio**
  - Cache hits
  - Cache misses
  - Hit rate percentage
  - Query: `cache_hits_total`, `cache_misses_total`, `cache_hit_rate`

- **Cache Size**
  - Current cache size
  - Cache evictions
  - Query: `cache_size_bytes`, `cache_evictions_total`

### 6. Error & Exception Metrics
**Why:** Track application errors and exceptions

- **Exception Rate**
  - Exceptions by type
  - Exceptions by endpoint
  - Query: `exceptions_total{type, endpoint}`

- **HTTP Error Rates**
  - 4xx errors (client errors)
  - 5xx errors (server errors)
  - Error rate by endpoint
  - Query: `http_requests_total{status_code=~"4..|5.."}`

- **Error Recovery**
  - Retry attempts
  - Circuit breaker state
  - Query: `retry_attempts_total`, `circuit_breaker_state`

### 7. Performance Metrics
**Why:** Identify performance bottlenecks

- **Garbage Collection**
  - GC pause time
  - GC frequency
  - Gen 0/1/2 collections
  - Query: `dotnet_gc_pause_seconds`, `dotnet_gc_collections_total`

- **Thread Pool**
  - Active threads
  - Thread pool queue length
  - Query: `dotnet_threadpool_threads_active`, `dotnet_threadpool_queue_length`

- **Response Time by Endpoint**
  - Average response time per endpoint
  - Slowest endpoints
  - Query: `http_request_duration_seconds{endpoint}`

### 8. External Service Metrics
**Why:** Monitor dependencies and external integrations

- **SMTP Service Health**
  - Email delivery time
  - SMTP connection failures
  - Query: `smtp_delivery_duration_seconds`, `smtp_connection_failures_total`

- **Google OAuth**
  - OAuth authentication attempts
  - OAuth failures
  - Query: `oauth_google_attempts_total`, `oauth_google_failures_total`

### 9. Resource Utilization
**Why:** Plan for capacity and scaling

- **Disk I/O**
  - Read/write operations per second
  - Disk queue length
  - Query: `disk_read_bytes_total`, `disk_write_bytes_total`, `disk_queue_length`

- **File System**
  - Disk space usage
  - Inode usage
  - Query: `disk_usage_percent`, `disk_inodes_used_percent`

### 10. Custom Business Metrics
**Why:** Track KPIs specific to your application

- **User Engagement**
  - Daily active users (DAU)
  - Monthly active users (MAU)
  - Session duration
  - Query: `users_dau`, `users_mau`, `session_duration_seconds`

- **Content Metrics**
  - Most viewed components
  - Most popular builds
  - Search query trends
  - Query: `components_views_total{component_id}`, `builds_views_total{build_id}`

## Implementation Priority

### High Priority (Implement First)
1. Database connection pool metrics
2. RabbitMQ queue depth and processing rates
3. Authentication success/failure rates
4. HTTP error rates by endpoint
5. Cache hit/miss ratio

### Medium Priority
1. Build operation metrics
2. Component operation metrics
3. Rate limiting metrics
4. Exception tracking
5. Garbage collection metrics

### Low Priority (Nice to Have)
1. User engagement metrics
2. Content popularity metrics
3. Disk I/O metrics
4. Thread pool metrics

## Alerting Recommendations

Set up alerts for:
- CPU usage > 80% for 5 minutes
- Memory usage > 90%
- Database connection pool exhaustion
- RabbitMQ queue depth > 1000 messages
- Error rate > 5% of requests
- Response time p95 > 1 second
- Cache hit rate < 70%

## Tools & Libraries

For implementing these metrics:
- **Prometheus.NET** (already in use) - for custom metrics
- **prometheus-net.AspNetCore** (already in use) - for HTTP metrics
- **prometheus-net.SystemMetrics** - for system-level metrics (optional)
- **EF Core Prometheus** - for database metrics (if available)
- **RabbitMQ Prometheus Exporter** - for RabbitMQ metrics

## Example Implementation

```csharp
// Example: Database query duration metric
private static readonly Histogram DbQueryDuration = Metrics
    .CreateHistogram(
        "efcore_query_duration_seconds",
        "Duration of database queries in seconds",
        new HistogramConfiguration
        {
            Buckets = Histogram.ExponentialBuckets(0.001, 2, 16) // 1ms to 32s
        });

// Usage in DbContext interceptor
public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
{
    using (DbQueryDuration.NewTimer())
    {
        return await base.SaveChangesAsync(cancellationToken);
    }
}
```

