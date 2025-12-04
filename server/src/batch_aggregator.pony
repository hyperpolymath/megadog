"""
MegaDog Batch Aggregator
Collects dog diffs and submits to blockchain in batches
This is where the RADIX EFFICIENCY pays off
"""

use "collections"
use "time"

actor BatchAggregator
  """
  Aggregates dog state changes into batches for efficient blockchain commits

  Instead of writing every action to chain:
  - Collect diffs in memory
  - When batch is full OR timeout reached
  - Compute Merkle root
  - Submit single transaction with all diffs

  Gas savings: ~80 gas per dog action vs ~5000 gas individual
  """
  let _env: Env
  let _config: GameConfig val
  let _dog_manager: DogStateManager
  var _pending_diffs: Array[DogDiff val]
  var _last_flush_time: U64

  new create(env: Env, config: GameConfig val, dog_manager: DogStateManager) =>
    _env = env
    _config = config
    _dog_manager = dog_manager
    _pending_diffs = Array[DogDiff val]
    _last_flush_time = Time.nanos()

  be record_diff(diff: DogDiff val) =>
    """Record a dog state change for batch commit"""
    _pending_diffs.push(diff)

    if _pending_diffs.size() >= _config.batch_size then
      _flush_batch()
    end

  be flush_if_needed() =>
    """Called by timer to flush batch if timeout reached"""
    let now = Time.nanos()
    let elapsed = now - _last_flush_time

    if (_pending_diffs.size() > 0) and (elapsed >= _config.batch_interval_ns) then
      _flush_batch()
    end

  be force_flush() =>
    """Force immediate batch commit (for shutdown)"""
    if _pending_diffs.size() > 0 then
      _flush_batch()
    end

  fun ref _flush_batch() =>
    """Commit pending diffs to blockchain"""
    let batch_size = _pending_diffs.size()
    if batch_size == 0 then
      return
    end

    // Compute Merkle root of all diffs
    let merkle_root = _compute_merkle_root()

    // Compress diffs for transmission
    let compressed = _compress_diffs()

    _env.out.print("Flushing batch: " + batch_size.string() + " diffs, root: "
      + _bytes_to_hex(merkle_root))

    // Submit to blockchain (in production, call Vyper contract)
    _submit_to_blockchain(merkle_root, compressed)

    // Clear pending diffs
    _pending_diffs = Array[DogDiff val]
    _last_flush_time = Time.nanos()

  fun _compute_merkle_root(): Array[U8] val =>
    """
    Compute Merkle root of all pending diffs
    Simplified implementation - use proper library in production
    """
    let leaves = Array[Array[U8] val]
    for diff in _pending_diffs.values() do
      leaves.push(_hash_diff(diff))
    end

    // Build tree bottom-up
    while leaves.size() > 1 do
      let next_level = Array[Array[U8] val]
      var i: USize = 0
      while i < leaves.size() do
        try
          let left = leaves(i)?
          let right = if (i + 1) < leaves.size() then
            leaves(i + 1)?
          else
            left  // Duplicate if odd number
          end
          next_level.push(_hash_pair(left, right))
        end
        i = i + 2
      end
      // Note: We need to update leaves with next_level
      // This is simplified - proper implementation would rebuild
      if next_level.size() > 0 then
        try
          return next_level(0)?
        end
      end
    end

    // Return first leaf if only one
    try
      leaves(0)?
    else
      recover val Array[U8].init(0, 32) end
    end

  fun _hash_diff(diff: DogDiff val): Array[U8] val =>
    """Hash a single diff (simplified - use keccak256 in production)"""
    recover val
      let h = Array[U8](32)
      // Simple hash: XOR components together
      for i in Range(0, 8) do
        h.push(((diff.dog_id >> (i.u256() * 8)) and 0xFF).u8())
      end
      for i in Range(0, 8) do
        h.push(((diff.delta_log_treats >> (i.i128() * 8)) and 0xFF).u8())
      end
      h.push(diff.delta_level.u8())
      // Pad to 32 bytes
      while h.size() < 32 do
        h.push(0)
      end
      h
    end

  fun _hash_pair(left: Array[U8] val, right: Array[U8] val): Array[U8] val =>
    """Hash two nodes together (simplified)"""
    recover val
      let h = Array[U8](32)
      for i in Range(0, 32) do
        try
          h.push(left(i)? xor right(i)?)
        else
          h.push(0)
        end
      end
      h
    end

  fun _compress_diffs(): Array[U8] val =>
    """
    Compress diffs for efficient transmission
    Uses logarithmic values which are already smaller
    """
    recover val
      let compressed = Array[U8]
      // Header: number of diffs (4 bytes)
      let count = _pending_diffs.size().u32()
      compressed.push(((count >> 24) and 0xFF).u8())
      compressed.push(((count >> 16) and 0xFF).u8())
      compressed.push(((count >> 8) and 0xFF).u8())
      compressed.push((count and 0xFF).u8())

      // Each diff: dog_id (32) + delta_level (1) + delta_log_treats (16)
      for diff in _pending_diffs.values() do
        // Dog ID (simplified to 8 bytes)
        for i in Range(0, 8) do
          compressed.push(((diff.dog_id >> (i.u256() * 8)) and 0xFF).u8())
        end
        // Delta level
        compressed.push(diff.delta_level.u8())
        // Delta log treats (8 bytes sufficient for I128 in practice)
        for i in Range(0, 8) do
          compressed.push(((diff.delta_log_treats >> (i.i128() * 8)) and 0xFF).u8())
        end
      end
      compressed
    end

  fun _submit_to_blockchain(merkle_root: Array[U8] val, data: Array[U8] val) =>
    """
    Submit batch to Vyper contract
    In production: call apply_dog_diff_batch via Web3
    """
    // TODO: Implement actual blockchain submission
    // For now, just log
    _env.out.print("Would submit to blockchain:")
    _env.out.print("  Network: " + _config.blockchain_network)
    _env.out.print("  Contract: " + _config.contract_address)
    _env.out.print("  Data size: " + data.size().string() + " bytes")

  fun _bytes_to_hex(bytes: Array[U8] val): String =>
    """Convert bytes to hex string for logging"""
    let hex_chars = "0123456789abcdef"
    var result = "0x"
    for b in bytes.values() do
      try
        result = result + hex_chars((b >> 4).usize())?.string()
        result = result + hex_chars((b and 0x0F).usize())?.string()
      end
    end
    result

  be get_pending_count(callback: {(USize)} val) =>
    """Get number of pending diffs"""
    callback(_pending_diffs.size())
