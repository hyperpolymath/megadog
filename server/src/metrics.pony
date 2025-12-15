"""
MegaDog Server Metrics
Collects and exposes server performance metrics
RSR Compliant: Pony Actor Model
"""

use "collections"
use "time"

actor MetricsCollector
  """
  Collects server metrics for monitoring
  Exposes via HTTP endpoint for Prometheus scraping
  """
  let _env: Env
  var _requests_total: U64
  var _requests_success: U64
  var _requests_failed: U64
  var _active_connections: USize
  var _dogs_created: U64
  var _dogs_merged: U64
  var _batches_submitted: U64
  var _batch_diffs_total: U64
  var _anti_cheat_blocks: U64
  var _start_time: U64
  var _latency_samples: Array[U64]

  new create(env: Env) =>
    _env = env
    _requests_total = 0
    _requests_success = 0
    _requests_failed = 0
    _active_connections = 0
    _dogs_created = 0
    _dogs_merged = 0
    _batches_submitted = 0
    _batch_diffs_total = 0
    _anti_cheat_blocks = 0
    _start_time = Time.nanos()
    _latency_samples = Array[U64](1000)

  be record_request(success: Bool, latency_ns: U64) =>
    """Record a request"""
    _requests_total = _requests_total + 1
    if success then
      _requests_success = _requests_success + 1
    else
      _requests_failed = _requests_failed + 1
    end

    // Keep last 1000 latency samples
    _latency_samples.push(latency_ns)
    if _latency_samples.size() > 1000 then
      try _latency_samples.shift()? end
    end

  be record_connection_opened() =>
    """Record a new connection"""
    _active_connections = _active_connections + 1

  be record_connection_closed() =>
    """Record a closed connection"""
    if _active_connections > 0 then
      _active_connections = _active_connections - 1
    end

  be record_dog_created() =>
    """Record a dog creation"""
    _dogs_created = _dogs_created + 1

  be record_dog_merged() =>
    """Record a dog merge"""
    _dogs_merged = _dogs_merged + 1

  be record_batch_submitted(diff_count: USize) =>
    """Record a batch submission"""
    _batches_submitted = _batches_submitted + 1
    _batch_diffs_total = _batch_diffs_total + diff_count.u64()

  be record_anti_cheat_block() =>
    """Record an anti-cheat block"""
    _anti_cheat_blocks = _anti_cheat_blocks + 1

  be get_metrics(callback: {(ServerMetrics val)} val) =>
    """Get current metrics snapshot"""
    let uptime = Time.nanos() - _start_time

    // Calculate percentile latencies
    let p50 = _calculate_percentile(50)
    let p95 = _calculate_percentile(95)
    let p99 = _calculate_percentile(99)

    let metrics = ServerMetrics.create(
      _requests_total,
      _requests_success,
      _requests_failed,
      _active_connections,
      _dogs_created,
      _dogs_merged,
      _batches_submitted,
      _batch_diffs_total,
      _anti_cheat_blocks,
      uptime,
      p50,
      p95,
      p99
    )

    callback(metrics)

  be get_prometheus_output(callback: {(String)} val) =>
    """Get metrics in Prometheus exposition format"""
    let uptime = Time.nanos() - _start_time
    let p50 = _calculate_percentile(50)
    let p95 = _calculate_percentile(95)
    let p99 = _calculate_percentile(99)

    let output =
      "# HELP megadog_requests_total Total number of requests\n" +
      "# TYPE megadog_requests_total counter\n" +
      "megadog_requests_total " + _requests_total.string() + "\n\n" +

      "# HELP megadog_requests_success Successful requests\n" +
      "# TYPE megadog_requests_success counter\n" +
      "megadog_requests_success " + _requests_success.string() + "\n\n" +

      "# HELP megadog_requests_failed Failed requests\n" +
      "# TYPE megadog_requests_failed counter\n" +
      "megadog_requests_failed " + _requests_failed.string() + "\n\n" +

      "# HELP megadog_active_connections Current active connections\n" +
      "# TYPE megadog_active_connections gauge\n" +
      "megadog_active_connections " + _active_connections.string() + "\n\n" +

      "# HELP megadog_dogs_created Total dogs created\n" +
      "# TYPE megadog_dogs_created counter\n" +
      "megadog_dogs_created " + _dogs_created.string() + "\n\n" +

      "# HELP megadog_dogs_merged Total dogs merged\n" +
      "# TYPE megadog_dogs_merged counter\n" +
      "megadog_dogs_merged " + _dogs_merged.string() + "\n\n" +

      "# HELP megadog_batches_submitted Total batches submitted\n" +
      "# TYPE megadog_batches_submitted counter\n" +
      "megadog_batches_submitted " + _batches_submitted.string() + "\n\n" +

      "# HELP megadog_batch_diffs_total Total diffs in batches\n" +
      "# TYPE megadog_batch_diffs_total counter\n" +
      "megadog_batch_diffs_total " + _batch_diffs_total.string() + "\n\n" +

      "# HELP megadog_anti_cheat_blocks Anti-cheat blocks\n" +
      "# TYPE megadog_anti_cheat_blocks counter\n" +
      "megadog_anti_cheat_blocks " + _anti_cheat_blocks.string() + "\n\n" +

      "# HELP megadog_uptime_seconds Server uptime in seconds\n" +
      "# TYPE megadog_uptime_seconds gauge\n" +
      "megadog_uptime_seconds " + (uptime / 1_000_000_000).string() + "\n\n" +

      "# HELP megadog_latency_p50_ms 50th percentile latency in ms\n" +
      "# TYPE megadog_latency_p50_ms gauge\n" +
      "megadog_latency_p50_ms " + (p50 / 1_000_000).string() + "\n\n" +

      "# HELP megadog_latency_p95_ms 95th percentile latency in ms\n" +
      "# TYPE megadog_latency_p95_ms gauge\n" +
      "megadog_latency_p95_ms " + (p95 / 1_000_000).string() + "\n\n" +

      "# HELP megadog_latency_p99_ms 99th percentile latency in ms\n" +
      "# TYPE megadog_latency_p99_ms gauge\n" +
      "megadog_latency_p99_ms " + (p99 / 1_000_000).string() + "\n"

    callback(output)

  fun _calculate_percentile(percentile: USize): U64 =>
    """Calculate latency percentile"""
    if _latency_samples.size() == 0 then
      return 0
    end

    // Sort samples (simplified - use proper sorting in production)
    let sorted = Array[U64]
    for s in _latency_samples.values() do
      sorted.push(s)
    end

    // Simple bubble sort (replace with quicksort in production)
    for i in Range(0, sorted.size()) do
      for j in Range(0, sorted.size() - i - 1) do
        try
          if sorted(j)? > sorted(j + 1)? then
            let temp = sorted(j)?
            sorted(j)? = sorted(j + 1)?
            sorted(j + 1)? = temp
          end
        end
      end
    end

    // Get percentile index
    let index = (percentile * sorted.size()) / 100
    try
      sorted(index)?
    else
      0
    end


class val ServerMetrics
  """Immutable snapshot of server metrics"""
  let requests_total: U64
  let requests_success: U64
  let requests_failed: U64
  let active_connections: USize
  let dogs_created: U64
  let dogs_merged: U64
  let batches_submitted: U64
  let batch_diffs_total: U64
  let anti_cheat_blocks: U64
  let uptime_ns: U64
  let latency_p50_ns: U64
  let latency_p95_ns: U64
  let latency_p99_ns: U64

  new val create(
    requests_total': U64,
    requests_success': U64,
    requests_failed': U64,
    active_connections': USize,
    dogs_created': U64,
    dogs_merged': U64,
    batches_submitted': U64,
    batch_diffs_total': U64,
    anti_cheat_blocks': U64,
    uptime_ns': U64,
    latency_p50_ns': U64,
    latency_p95_ns': U64,
    latency_p99_ns': U64
  ) =>
    requests_total = requests_total'
    requests_success = requests_success'
    requests_failed = requests_failed'
    active_connections = active_connections'
    dogs_created = dogs_created'
    dogs_merged = dogs_merged'
    batches_submitted = batches_submitted'
    batch_diffs_total = batch_diffs_total'
    anti_cheat_blocks = anti_cheat_blocks'
    uptime_ns = uptime_ns'
    latency_p50_ns = latency_p50_ns'
    latency_p95_ns = latency_p95_ns'
    latency_p99_ns = latency_p99_ns'

  fun success_rate(): F64 =>
    """Calculate success rate"""
    if requests_total == 0 then
      return 100.0
    end
    (requests_success.f64() / requests_total.f64()) * 100.0

  fun requests_per_second(): F64 =>
    """Calculate requests per second"""
    if uptime_ns == 0 then
      return 0.0
    end
    requests_total.f64() / (uptime_ns.f64() / 1_000_000_000.0)
