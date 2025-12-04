"""
MegaDog WebSocket Server
Handles client connections from Android app
"""

use "net"
use "collections"

actor WebSocketServer
  """
  WebSocket server for Android client connections
  Handles game actions and pushes updates
  """
  let _env: Env
  let _config: GameConfig val
  let _dog_manager: DogStateManager
  let _batch_aggregator: BatchAggregator
  let _anti_cheat: AntiCheatEngine
  var _listener: (TCPListener | None)

  new create(
    env: Env,
    config: GameConfig val,
    dog_manager: DogStateManager,
    batch_aggregator: BatchAggregator,
    anti_cheat: AntiCheatEngine
  ) ? =>
    _env = env
    _config = config
    _dog_manager = dog_manager
    _batch_aggregator = batch_aggregator
    _anti_cheat = anti_cheat

    _listener = TCPListener(
      TCPListenAuth(_env.root),
      WebSocketListenerNotify(
        _env,
        _config,
        _dog_manager,
        _batch_aggregator,
        _anti_cheat
      ),
      _config.host,
      _config.port.string()
    )

  be shutdown() =>
    """Gracefully shutdown the server"""
    match _listener
    | let l: TCPListener => l.close()
    end
    _batch_aggregator.force_flush()


class WebSocketListenerNotify is TCPListenNotify
  let _env: Env
  let _config: GameConfig val
  let _dog_manager: DogStateManager
  let _batch_aggregator: BatchAggregator
  let _anti_cheat: AntiCheatEngine

  new iso create(
    env: Env,
    config: GameConfig val,
    dog_manager: DogStateManager,
    batch_aggregator: BatchAggregator,
    anti_cheat: AntiCheatEngine
  ) =>
    _env = env
    _config = config
    _dog_manager = dog_manager
    _batch_aggregator = batch_aggregator
    _anti_cheat = anti_cheat

  fun ref listening(listen: TCPListener ref) =>
    _env.out.print("WebSocket server listening...")

  fun ref not_listening(listen: TCPListener ref) =>
    _env.out.print("WebSocket server failed to listen")

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _env.out.print("Client connected")
    WebSocketConnectionNotify(
      _env,
      _config,
      _dog_manager,
      _batch_aggregator,
      _anti_cheat
    )


class WebSocketConnectionNotify is TCPConnectionNotify
  """
  Handle individual WebSocket connections
  Simplified protocol (in production, use proper WebSocket framing)
  """
  let _env: Env
  let _config: GameConfig val
  let _dog_manager: DogStateManager
  let _batch_aggregator: BatchAggregator
  let _anti_cheat: AntiCheatEngine
  var _user_id: String
  var _authenticated: Bool

  new iso create(
    env: Env,
    config: GameConfig val,
    dog_manager: DogStateManager,
    batch_aggregator: BatchAggregator,
    anti_cheat: AntiCheatEngine
  ) =>
    _env = env
    _config = config
    _dog_manager = dog_manager
    _batch_aggregator = batch_aggregator
    _anti_cheat = anti_cheat
    _user_id = ""
    _authenticated = false

  fun ref accepted(conn: TCPConnection ref) =>
    // Send welcome message
    conn.write("{\"type\":\"welcome\",\"version\":\"0.1.0\"}\n")

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
    """Process incoming messages"""
    let message = String.from_array(consume data)

    // Simple JSON parsing (use proper parser in production)
    if message.contains("\"type\":\"auth\"") then
      _handle_auth(conn, message)
    elseif message.contains("\"type\":\"mint\"") then
      _handle_mint(conn)
    elseif message.contains("\"type\":\"merge\"") then
      _handle_merge(conn, message)
    elseif message.contains("\"type\":\"prestige\"") then
      _handle_prestige(conn, message)
    elseif message.contains("\"type\":\"get_dogs\"") then
      _handle_get_dogs(conn)
    elseif message.contains("\"type\":\"health\"") then
      conn.write("{\"type\":\"health\",\"status\":\"ok\"}\n")
    else
      conn.write("{\"type\":\"error\",\"message\":\"Unknown message type\"}\n")
    end
    true

  fun ref _handle_auth(conn: TCPConnection ref, message: String) =>
    """Handle authentication (simplified - use proper auth in production)"""
    // Extract user_id from message (simplified parsing)
    // In production: verify signature, check wallet ownership
    _user_id = "0x1234567890abcdef"  // Placeholder
    _authenticated = true
    conn.write("{\"type\":\"auth_ok\",\"user_id\":\"" + _user_id + "\"}\n")

  fun ref _handle_mint(conn: TCPConnection ref) =>
    """Handle mint starter dog request"""
    if not _authenticated then
      conn.write("{\"type\":\"error\",\"message\":\"Not authenticated\"}\n")
      return
    end

    // Anti-cheat validation
    _anti_cheat.validate_action(
      _user_id,
      ActionMint,
      {(result: (Bool, String))(conn, dog_manager = _dog_manager, user_id = _user_id, batch_agg = _batch_aggregator) =>
        (let allowed, let reason) = result
        if not allowed then
          conn.write("{\"type\":\"error\",\"message\":\"" + reason + "\"}\n")
          return
        end

        // Mint the dog
        dog_manager.mint_starter_dog(
          user_id,
          {(dog: Dog val)(conn) =>
            let response = "{\"type\":\"minted\",\"dog\":{" +
              "\"id\":" + dog.id.string() + "," +
              "\"level\":" + dog.level.string() + "," +
              "\"log_treats\":" + dog.log_treats.string() +
              "}}\n"
            conn.write(response)
          } val
        )
      } val
    )

  fun ref _handle_merge(conn: TCPConnection ref, message: String) =>
    """Handle merge dogs request"""
    if not _authenticated then
      conn.write("{\"type\":\"error\",\"message\":\"Not authenticated\"}\n")
      return
    end

    // Extract dog IDs from message (simplified)
    // Format: {"type":"merge","dog1_id":1,"dog2_id":2}
    let dog1_id: U256 = 1  // Placeholder - parse from message
    let dog2_id: U256 = 2  // Placeholder - parse from message

    _anti_cheat.validate_action(
      _user_id,
      ActionMerge,
      {(result: (Bool, String))(conn, dog_manager = _dog_manager, user_id = _user_id, batch_agg = _batch_aggregator, d1 = dog1_id, d2 = dog2_id) =>
        (let allowed, let reason) = result
        if not allowed then
          conn.write("{\"type\":\"error\",\"message\":\"" + reason + "\"}\n")
          return
        end

        // Merge the dogs
        dog_manager.merge_dogs(
          user_id,
          d1,
          d2,
          {(result: (Dog val | MergeError))(conn, batch_agg) =>
            match result
            | let dog: Dog val =>
              // Record diff for batch commit
              let diff = DogDiff.create(dog.id, 1, 0, dog.fractal_seed)
              batch_agg.record_diff(diff)

              let response = "{\"type\":\"merged\",\"dog\":{" +
                "\"id\":" + dog.id.string() + "," +
                "\"level\":" + dog.level.string() + "," +
                "\"log_treats\":" + dog.log_treats.string() +
                "}}\n"
              conn.write(response)
            | let err: MergeError =>
              conn.write("{\"type\":\"error\",\"message\":\"" + err.message + "\"}\n")
            end
          } val
        )
      } val
    )

  fun ref _handle_prestige(conn: TCPConnection ref, message: String) =>
    """Handle prestige reset request"""
    if not _authenticated then
      conn.write("{\"type\":\"error\",\"message\":\"Not authenticated\"}\n")
      return
    end

    let dog_id: U256 = 1  // Placeholder - parse from message

    _anti_cheat.validate_action(
      _user_id,
      ActionPrestige,
      {(result: (Bool, String))(conn, dog_manager = _dog_manager, user_id = _user_id, d = dog_id) =>
        (let allowed, let reason) = result
        if not allowed then
          conn.write("{\"type\":\"error\",\"message\":\"" + reason + "\"}\n")
          return
        end

        dog_manager.prestige_reset(
          user_id,
          d,
          {(result: (Dog val | PrestigeError))(conn) =>
            match result
            | let dog: Dog val =>
              conn.write("{\"type\":\"prestiged\",\"dog_id\":" + dog.id.string() + "}\n")
            | let err: PrestigeError =>
              conn.write("{\"type\":\"error\",\"message\":\"" + err.message + "\"}\n")
            end
          } val
        )
      } val
    )

  fun ref _handle_get_dogs(conn: TCPConnection ref) =>
    """Get all dogs for current user"""
    if not _authenticated then
      conn.write("{\"type\":\"error\",\"message\":\"Not authenticated\"}\n")
      return
    end

    _dog_manager.get_user_dogs(
      _user_id,
      {(dogs: Array[Dog val] val)(conn) =>
        var response = "{\"type\":\"dogs\",\"dogs\":["
        var first = true
        for dog in dogs.values() do
          if not first then
            response = response + ","
          end
          first = false
          response = response + "{" +
            "\"id\":" + dog.id.string() + "," +
            "\"level\":" + dog.level.string() + "," +
            "\"log_treats\":" + dog.log_treats.string() +
            "}"
        end
        response = response + "]}\n"
        conn.write(response)
      } val
    )

  fun ref closed(conn: TCPConnection ref) =>
    _env.out.print("Client disconnected: " + _user_id)

  fun ref connect_failed(conn: TCPConnection ref) =>
    None
