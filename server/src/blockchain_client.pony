"""
MegaDog Blockchain Client
Interfaces with Vyper smart contracts on Polygon
RSR Compliant: Pony Actor Model
"""

use "net"
use "collections"
use "time"

actor BlockchainClient
  """
  Handles all blockchain interactions
  - Contract calls
  - Transaction signing
  - Event monitoring
  """
  let _env: Env
  let _config: GameConfig val
  var _current_block: U64
  var _pending_txs: Map[String, PendingTransaction]
  var _connected: Bool

  new create(env: Env, config: GameConfig val) =>
    _env = env
    _config = config
    _current_block = 0
    _pending_txs = Map[String, PendingTransaction]
    _connected = false

  be connect() =>
    """Establish connection to blockchain RPC"""
    _env.out.print("Connecting to blockchain: " + _config.blockchain_rpc)
    // In production: establish HTTP/WebSocket connection
    _connected = true
    _env.out.print("Blockchain client connected")

  be get_current_block(callback: {(U64)} val) =>
    """Get current block number"""
    // In production: query eth_blockNumber
    callback(_current_block)

  be set_current_block(block: U64) =>
    """Update current block (called by block monitor)"""
    _current_block = block

  be submit_batch(
    merkle_root: Array[U8] val,
    compressed_diffs: Array[U8] val,
    callback: {((Bool, String))} val
  ) =>
    """
    Submit a batch of diffs to the blockchain
    Calls apply_dog_diff_batch on Vyper contract
    """
    if not _connected then
      callback((false, "Not connected to blockchain"))
      return
    end

    let tx_hash = _generate_tx_hash(merkle_root)

    _env.out.print("Submitting batch to blockchain:")
    _env.out.print("  Merkle root: " + _bytes_to_hex(merkle_root))
    _env.out.print("  Data size: " + compressed_diffs.size().string() + " bytes")
    _env.out.print("  Contract: " + _config.contract_address)

    // Record pending transaction
    _pending_txs(tx_hash) = PendingTransaction.create(
      tx_hash,
      merkle_root,
      Time.nanos()
    )

    // In production: sign and send transaction via JSON-RPC
    // For now, simulate success after "confirmation"
    callback((true, tx_hash))

  be verify_dog_ownership(
    dog_id: U256,
    claimed_owner: String,
    callback: {(Bool)} val
  ) =>
    """Verify dog ownership on-chain"""
    // In production: call verify_dog_ownership view function
    // For now, return true (trust server state)
    callback(true)

  be get_dog_state(
    dog_id: U256,
    callback: {((Dog val | None))} val
  ) =>
    """Get dog state from blockchain"""
    // In production: call get_dog view function
    // For now, return None (server has authoritative state)
    callback(None)

  be mint_on_chain(
    owner: String,
    callback: {((Bool, U256))} val
  ) =>
    """Mint a new dog on-chain"""
    if not _connected then
      callback((false, 0))
      return
    end

    _env.out.print("Minting dog on-chain for: " + owner)
    // In production: call mint_starter_dog
    // Return placeholder ID for now
    callback((true, 1))

  be get_game_economics(
    callback: {((U64, U64, U64))} val
  ) =>
    """Get on-chain game economics for transparency"""
    // Returns: (total_gas, total_dogs, avg_gas_per_dog)
    // In production: call get_game_economics view function
    callback((0, 0, 0))

  be get_connection_status(callback: {(Bool)} val) =>
    """Check if connected to blockchain"""
    callback(_connected)

  fun _generate_tx_hash(data: Array[U8] val): String =>
    """Generate a transaction hash (simplified)"""
    var hash: String = "0x"
    for i in Range(0, 32) do
      try
        let byte = data(i % data.size())?
        hash = hash + _byte_to_hex(byte)
      else
        hash = hash + "00"
      end
    end
    hash

  fun _bytes_to_hex(bytes: Array[U8] val): String =>
    """Convert bytes to hex string"""
    let hex_chars = "0123456789abcdef"
    var result = "0x"
    for b in bytes.values() do
      try
        result = result + hex_chars((b >> 4).usize())?.string()
        result = result + hex_chars((b and 0x0F).usize())?.string()
      end
    end
    result

  fun _byte_to_hex(b: U8): String =>
    """Convert single byte to hex"""
    let hex_chars = "0123456789abcdef"
    try
      hex_chars((b >> 4).usize())?.string() + hex_chars((b and 0x0F).usize())?.string()
    else
      "00"
    end


class val PendingTransaction
  """Represents a pending blockchain transaction"""
  let hash: String
  let merkle_root: Array[U8] val
  let submitted_at: U64
  var confirmed: Bool
  var confirmations: U32

  new val create(
    hash': String,
    merkle_root': Array[U8] val,
    submitted_at': U64
  ) =>
    hash = hash'
    merkle_root = merkle_root'
    submitted_at = submitted_at'
    confirmed = false
    confirmations = 0


actor BlockMonitor
  """
  Monitors blockchain for new blocks and events
  Updates game state when relevant events occur
  """
  let _env: Env
  let _config: GameConfig val
  let _blockchain: BlockchainClient
  let _dog_manager: DogStateManager
  var _last_block: U64
  var _running: Bool

  new create(
    env: Env,
    config: GameConfig val,
    blockchain: BlockchainClient,
    dog_manager: DogStateManager
  ) =>
    _env = env
    _config = config
    _blockchain = blockchain
    _dog_manager = dog_manager
    _last_block = 0
    _running = false

  be start() =>
    """Start monitoring for new blocks"""
    _running = true
    _env.out.print("Block monitor started")
    _poll_new_blocks()

  be stop() =>
    """Stop monitoring"""
    _running = false
    _env.out.print("Block monitor stopped")

  be _poll_new_blocks() =>
    """Poll for new blocks (called periodically)"""
    if not _running then
      return
    end

    _blockchain.get_current_block(
      {(block: U64)(self = this, env = _env, dog_manager = _dog_manager, blockchain = _blockchain) =>
        if block > self._last_block then
          env.out.print("New block: " + block.string())
          dog_manager.set_current_block(block)
          blockchain.set_current_block(block)
          // In production: scan for relevant events
        end
      } val
    )

  var _last_block: U64
    // This is a workaround for Pony's reference capability rules
    // In production, use proper actor state management
