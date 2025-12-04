"""
MegaDog Dog Entity and State Management
Logarithmic storage for efficiency at scale
"""

use "collections"
use "time"

class val Dog
  """
  Immutable dog state (reference capability: val)
  All values stored logarithmically where applicable
  """
  let id: U256
  let owner: String  // Wallet address
  let level: U8
  let log_treats: I128      // ln(treats) * PRECISION
  let log_merge_count: I128 // ln(merges) * PRECISION
  let fractal_seed: Array[U8] val  // 32 bytes for Mandelbrot generation
  let birth_block: U64
  let last_update_block: U64

  new val create(
    id': U256,
    owner': String,
    level': U8,
    log_treats': I128,
    log_merge_count': I128,
    fractal_seed': Array[U8] val,
    birth_block': U64,
    last_update_block': U64
  ) =>
    id = id'
    owner = owner'
    level = level'
    log_treats = log_treats'
    log_merge_count = log_merge_count'
    fractal_seed = fractal_seed'
    birth_block = birth_block'
    last_update_block = last_update_block'

  new val starter(id': U256, owner': String, seed: Array[U8] val, block: U64) =>
    """Create a level-1 starter dog"""
    id = id'
    owner = owner'
    level = 1
    log_treats = 4_605_170  // ln(100) * 10^6
    log_merge_count = 0
    fractal_seed = seed
    birth_block = block
    last_update_block = block

  fun actual_treats(precision: I128): U64 =>
    """Convert logarithmic treats back to actual value"""
    LogMath.exp_approx(log_treats, precision)

  fun actual_merge_count(precision: I128): U64 =>
    """Convert logarithmic merge count back to actual value"""
    LogMath.exp_approx(log_merge_count, precision)


class val DogDiff
  """
  Differential update for a dog (minimises blockchain storage)
  """
  let dog_id: U256
  let delta_level: I8           // Level change (-1, 0, +1)
  let delta_log_treats: I128    // Change in log(treats)
  let new_fractal_seed: (Array[U8] val | None)  // Only if merged

  new val create(
    dog_id': U256,
    delta_level': I8,
    delta_log_treats': I128,
    new_fractal_seed': (Array[U8] val | None)
  ) =>
    dog_id = dog_id'
    delta_level = delta_level'
    delta_log_treats = delta_log_treats'
    new_fractal_seed = new_fractal_seed'


primitive LogMath
  """
  Logarithmic arithmetic for efficient storage
  All values scaled by PRECISION (default 10^6)
  """

  fun ln_approx(x: U64, precision: I128): I128 =>
    """
    Approximate natural log using bit-length
    ln(x) ≈ ln(2) * log2(x) ≈ 0.693147 * bitLength(x)
    """
    if x == 0 then
      return I128.min_value()  // Undefined, return minimum
    end

    var bit_length: U64 = 0
    var temp = x
    while temp > 0 do
      temp = temp >> 1
      bit_length = bit_length + 1
    end

    // ln(2) * 10^6 ≈ 693147
    (bit_length.i128() * 693147)

  fun exp_approx(ln_x: I128, precision: I128): U64 =>
    """
    Approximate e^x using power of 2
    e^x ≈ 2^(x/ln(2))
    """
    if ln_x < 0 then
      return 0
    end

    // x/ln(2) = ln_x / 693147
    let power_of_2 = ln_x / 693147

    if power_of_2 > 63 then
      return U64.max_value()
    end

    U64(1) << power_of_2.u64()

  fun add_logs(log_a: I128, log_b: I128, precision: I128): I128 =>
    """
    Compute ln(a + b) from ln(a) and ln(b)
    ln(a + b) = ln(a) + ln(1 + e^(ln(b) - ln(a)))
    """
    if log_a > log_b then
      let diff = log_b - log_a
      if diff < (-10 * precision) then
        // e^-10 ≈ 0, so a + b ≈ a
        return log_a
      end
      // Simplified: ln(1 + e^diff) ≈ e^diff for small diff
      log_a + ln_approx(precision.u64() + exp_approx(diff, precision), precision)
    else
      let diff = log_a - log_b
      if diff < (-10 * precision) then
        return log_b
      end
      log_b + ln_approx(precision.u64() + exp_approx(diff, precision), precision)
    end


primitive FractalSeed
  """Utilities for generating deterministic fractal seeds"""

  fun generate(dog_id: U256, owner: String, block: U64): Array[U8] val =>
    """
    Generate a deterministic 32-byte seed for Mandelbrot rendering
    Based on dog parameters - reproducible by anyone
    """
    // Simple hash combination (in production, use proper keccak256)
    let seed = recover val
      let s = Array[U8](32)
      // Mix dog_id bytes
      for i in Range(0, 8) do
        s.push(((dog_id >> (i.u256() * 8)) and 0xFF).u8())
      end
      // Mix block bytes
      for i in Range(0, 8) do
        s.push(((block >> (i.u64() * 8)) and 0xFF).u8())
      end
      // Mix owner bytes (simplified)
      for i in Range(0, 16) do
        try
          s.push(owner(i)?)
        else
          s.push(0)
        end
      end
      s
    end
    seed

  fun merge(seed1: Array[U8] val, seed2: Array[U8] val, block: U64): Array[U8] val =>
    """
    Generate new seed from two parent seeds (for merged dogs)
    XOR combination plus block entropy
    """
    let result = recover val
      let r = Array[U8](32)
      for i in Range(0, 32) do
        try
          let s1 = seed1(i)?
          let s2 = seed2(i)?
          let block_byte = ((block >> ((i.u64() % 8) * 8)) and 0xFF).u8()
          r.push(s1 xor s2 xor block_byte)
        else
          r.push(0)
        end
      end
      r
    end
    result
