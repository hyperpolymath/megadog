"""
MegaDog Connection Manager
Tracks all connected clients and enables broadcasting
RSR Compliant: Pony Actor Model
"""

use "net"
use "collections"
use "time"

actor ConnectionManager
  """
  Manages all WebSocket connections
  - Track connected clients
  - Broadcast messages
  - Handle disconnections
  - Session management
  """
  let _env: Env
  let _config: GameConfig val
  var _connections: Map[String, ClientConnection]
  var _user_connections: Map[String, String]  // user_id -> connection_id
  var _next_connection_id: U64
  var _metrics: (MetricsCollector | None)

  new create(env: Env, config: GameConfig val) =>
    _env = env
    _config = config
    _connections = Map[String, ClientConnection]
    _user_connections = Map[String, String]
    _next_connection_id = 1
    _metrics = None

  be set_metrics(metrics: MetricsCollector) =>
    """Set metrics collector for connection tracking"""
    _metrics = metrics

  be register_connection(
    conn: TCPConnection tag,
    callback: {(String)} val
  ) =>
    """Register a new connection"""
    let conn_id = "conn_" + _next_connection_id.string()
    _next_connection_id = _next_connection_id + 1

    let client = ClientConnection.create(conn_id, conn, Time.nanos())
    _connections(conn_id) = client

    match _metrics
    | let m: MetricsCollector => m.record_connection_opened()
    end

    _env.out.print("Connection registered: " + conn_id)
    callback(conn_id)

  be authenticate_connection(
    conn_id: String,
    user_id: String,
    callback: {(Bool)} val
  ) =>
    """Associate a connection with a user"""
    try
      let client = _connections(conn_id)?

      // Check if user already has a connection
      try
        let old_conn_id = _user_connections(user_id)?
        if old_conn_id != conn_id then
          // User connecting from new device - disconnect old
          _disconnect_connection(old_conn_id)
        end
      end

      // Update mappings
      _user_connections(user_id) = conn_id
      let updated = ClientConnection.create(
        client.id,
        client.conn,
        client.connected_at,
        user_id,
        true,
        Time.nanos()
      )
      _connections(conn_id) = updated

      _env.out.print("Connection authenticated: " + conn_id + " -> " + user_id)
      callback(true)
    else
      callback(false)
    end

  be unregister_connection(conn_id: String) =>
    """Remove a connection"""
    try
      let client = _connections.remove(conn_id)?._2

      // Remove from user mapping if authenticated
      if client.authenticated then
        try _user_connections.remove(client.user_id)? end
      end

      match _metrics
      | let m: MetricsCollector => m.record_connection_closed()
      end

      _env.out.print("Connection unregistered: " + conn_id)
    end

  be broadcast_to_all(message: String) =>
    """Broadcast message to all connected clients"""
    for (_, client) in _connections.pairs() do
      client.conn.write(message)
    end

  be broadcast_to_authenticated(message: String) =>
    """Broadcast message to all authenticated clients"""
    for (_, client) in _connections.pairs() do
      if client.authenticated then
        client.conn.write(message)
      end
    end

  be send_to_user(user_id: String, message: String) =>
    """Send message to a specific user"""
    try
      let conn_id = _user_connections(user_id)?
      let client = _connections(conn_id)?
      client.conn.write(message)
    end

  be send_to_connection(conn_id: String, message: String) =>
    """Send message to a specific connection"""
    try
      let client = _connections(conn_id)?
      client.conn.write(message)
    end

  be get_connection_count(callback: {(USize)} val) =>
    """Get number of active connections"""
    callback(_connections.size())

  be get_authenticated_count(callback: {(USize)} val) =>
    """Get number of authenticated connections"""
    var count: USize = 0
    for (_, client) in _connections.pairs() do
      if client.authenticated then
        count = count + 1
      end
    end
    callback(count)

  be get_user_connection_id(
    user_id: String,
    callback: {((String | None))} val
  ) =>
    """Get connection ID for a user"""
    try
      callback(_user_connections(user_id)?)
    else
      callback(None)
    end

  be cleanup_stale_connections() =>
    """Remove connections that haven't authenticated within timeout"""
    let now = Time.nanos()
    let timeout_ns: U64 = 30_000_000_000  // 30 seconds

    let stale = Array[String]
    for (conn_id, client) in _connections.pairs() do
      if not client.authenticated then
        if (now - client.connected_at) > timeout_ns then
          stale.push(conn_id)
        end
      end
    end

    for conn_id in stale.values() do
      _disconnect_connection(conn_id)
    end

    if stale.size() > 0 then
      _env.out.print("Cleaned up " + stale.size().string() + " stale connections")
    end

  fun ref _disconnect_connection(conn_id: String) =>
    """Internal: Disconnect a connection"""
    try
      let client = _connections(conn_id)?
      // Send disconnect message
      client.conn.write("{\"type\":\"disconnect\",\"reason\":\"session_replaced\"}\n")
      client.conn.dispose()
      _connections.remove(conn_id)?

      if client.authenticated then
        try _user_connections.remove(client.user_id)? end
      end

      match _metrics
      | let m: MetricsCollector => m.record_connection_closed()
      end
    end


class val ClientConnection
  """Represents a connected client"""
  let id: String
  let conn: TCPConnection tag
  let connected_at: U64
  let user_id: String
  let authenticated: Bool
  let authenticated_at: U64

  new val create(
    id': String,
    conn': TCPConnection tag,
    connected_at': U64,
    user_id': String = "",
    authenticated': Bool = false,
    authenticated_at': U64 = 0
  ) =>
    id = id'
    conn = conn'
    connected_at = connected_at'
    user_id = user_id'
    authenticated = authenticated'
    authenticated_at = authenticated_at'

  fun session_duration_seconds(): U64 =>
    """Get session duration in seconds"""
    (Time.nanos() - connected_at) / 1_000_000_000


actor SessionCleanupTimer
  """Periodically cleans up stale connections"""
  let _env: Env
  let _connection_manager: ConnectionManager
  let _timers: Timers

  new create(
    env: Env,
    connection_manager: ConnectionManager,
    interval_seconds: U64 = 60
  ) =>
    _env = env
    _connection_manager = connection_manager
    _timers = Timers

    let timer = Timer(
      SessionCleanupNotify(_connection_manager),
      interval_seconds * 1_000_000_000,  // Convert to nanoseconds
      interval_seconds * 1_000_000_000
    )
    _timers(consume timer)


class iso SessionCleanupNotify is TimerNotify
  let _connection_manager: ConnectionManager

  new iso create(connection_manager: ConnectionManager) =>
    _connection_manager = connection_manager

  fun ref apply(timer: Timer, count: U64): Bool =>
    _connection_manager.cleanup_stale_connections()
    true
