"""
MegaDog Game Server - Main Entry Point
RSR Compliant: Pony Actor Model, Memory-Safe, No GC Pauses
"""

use "net"
use "collections"
use "time"

actor Main
  let _env: Env
  let _timers: Timers

  new create(env: Env) =>
    _env = env
    _timers = Timers

    _env.out.print("╔═══════════════════════════════════════════════════════╗")
    _env.out.print("║           MegaDog Server (Ethical Edition)            ║")
    _env.out.print("║   No fake money • Real ownership • Beautiful math     ║")
    _env.out.print("╚═══════════════════════════════════════════════════════╝")

    // Load configuration
    let config = GameConfig.default()
    _env.out.print("Config loaded: " + config.environment)

    // Create core actors
    let dog_manager = DogStateManager(_env, config)
    let batch_aggregator = BatchAggregator(_env, config, dog_manager)
    let anti_cheat = AntiCheatEngine(_env, config)

    // Start WebSocket server
    try
      let server = WebSocketServer(
        _env,
        config,
        dog_manager,
        batch_aggregator,
        anti_cheat
      )
      _env.out.print("Server listening on " + config.host + ":" + config.port.string())
    else
      _env.out.print("Failed to start server")
      _env.exitcode(1)
    end

    // Start batch commit timer
    let batch_timer = Timer(
      BatchCommitNotify(batch_aggregator),
      config.batch_interval_ns,
      config.batch_interval_ns
    )
    _timers(consume batch_timer)

class iso BatchCommitNotify is TimerNotify
  let _aggregator: BatchAggregator

  new iso create(aggregator: BatchAggregator) =>
    _aggregator = aggregator

  fun ref apply(timer: Timer, count: U64): Bool =>
    _aggregator.flush_if_needed()
    true
