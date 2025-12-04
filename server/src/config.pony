"""
MegaDog Game Configuration
Loaded from Nickel/Dhall configs at runtime
"""

class val GameConfig
  """Game server configuration (immutable, shareable)"""

  // Server settings
  let host: String
  let port: U32
  let environment: String

  // Blockchain settings
  let blockchain_network: String
  let blockchain_rpc: String
  let contract_address: String

  // Game economics (logarithmic)
  let log_precision: I128
  let starter_log_treats: I128
  let merge_bonus_multiplier: F64
  let prestige_threshold: U8

  // Batch settings
  let batch_size: USize
  let batch_interval_ns: U64

  // Anti-cheat
  let max_actions_per_minute: U32
  let max_merges_per_hour: U32
  let cooldown_seconds: U32

  // Fractal settings
  let fractal_iterations: U32
  let fractal_power: F64

  new val default() =>
    """Default development configuration"""
    host = "127.0.0.1"
    port = 8080
    environment = "development"

    blockchain_network = "localhost"
    blockchain_rpc = "http://localhost:8545"
    contract_address = "0x0000000000000000000000000000000000000000"

    log_precision = 1_000_000
    starter_log_treats = 4_605_170  // ln(100) * 10^6
    merge_bonus_multiplier = 1.5
    prestige_threshold = 50

    batch_size = 100
    batch_interval_ns = 60_000_000_000  // 60 seconds

    max_actions_per_minute = 60
    max_merges_per_hour = 500
    cooldown_seconds = 5

    fractal_iterations = 12
    fractal_power = 8.0

  new val from_env(env: Env) =>
    """Load from environment variables (for production)"""
    // TODO: Parse from MEGADOG_* environment variables
    // For now, use defaults
    host = "0.0.0.0"
    port = 8080
    environment = "production"

    blockchain_network = "polygon"
    blockchain_rpc = "https://polygon-rpc.com"
    contract_address = "0x0000000000000000000000000000000000000000"

    log_precision = 1_000_000
    starter_log_treats = 4_605_170
    merge_bonus_multiplier = 1.5
    prestige_threshold = 50

    batch_size = 100
    batch_interval_ns = 60_000_000_000

    max_actions_per_minute = 60
    max_merges_per_hour = 500
    cooldown_seconds = 5

    fractal_iterations = 12
    fractal_power = 8.0
