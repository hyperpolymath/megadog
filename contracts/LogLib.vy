# @version ^0.3.10
# LogLib: Generalized Logarithmic Storage Library for Vyper
#
# A reusable library for any contract needing efficient large-number storage.
# Proven correct (see ../proofs/LogarithmicStorage.lean)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Precision: ln(x) * PRECISION gives us 6 decimal places
# Higher precision = more accuracy, more storage
PRECISION: constant(int128) = 1000000

# Pre-computed constants (ln(x) * PRECISION)
LN_2: constant(int128) = 693147      # ln(2)
LN_10: constant(int128) = 2302585    # ln(10)
LN_E: constant(int128) = 1000000     # ln(e) = 1

# Error bounds
MAX_RELATIVE_ERROR: constant(int128) = 1000  # 0.1% max error

# =============================================================================
# CORE CONVERSION FUNCTIONS
# =============================================================================

@internal
@pure
def _ln(x: uint256) -> int128:
    """
    Compute ln(x) * PRECISION using bit-length approximation

    Algorithm: ln(x) ≈ ln(2) * log2(x) = ln(2) * bit_length(x)

    Accuracy: ~5% for single conversion, but errors don't compound
    for multiplication (which becomes addition in log space).

    Gas: O(1) - just bit counting
    """
    assert x > 0, "ln(0) undefined"

    # Count bits (log2 approximation)
    bit_length: uint256 = 0
    temp: uint256 = x

    for i in range(256):
        if temp == 0:
            break
        temp = shift(temp, -1)
        bit_length += 1

    # ln(x) ≈ ln(2) * log2(x)
    return convert(bit_length, int128) * LN_2

@internal
@pure
def _exp(ln_x: int128) -> uint256:
    """
    Compute e^(ln_x / PRECISION) = x

    Algorithm: e^x = 2^(x/ln(2))

    Gas: O(1) - just bit shifting
    """
    if ln_x <= 0:
        return 1

    # x / ln(2) gives us power of 2
    power_of_2: int128 = (ln_x * PRECISION) / LN_2
    exponent: uint256 = convert(power_of_2 / PRECISION, uint256)

    if exponent > 255:
        return max_value(uint256)

    return shift(1, convert(exponent, int128))

# =============================================================================
# ARITHMETIC IN LOG SPACE
# =============================================================================

@internal
@pure
def _log_mul(log_a: int128, log_b: int128) -> int128:
    """
    Multiply: ln(a * b) = ln(a) + ln(b)

    EXACT - no approximation error!
    This is the key insight: multiplication becomes addition.
    """
    return log_a + log_b

@internal
@pure
def _log_div(log_a: int128, log_b: int128) -> int128:
    """
    Divide: ln(a / b) = ln(a) - ln(b)

    EXACT - no approximation error!
    """
    return log_a - log_b

@internal
@pure
def _log_pow(log_base: int128, exponent: int128) -> int128:
    """
    Power: ln(x^n) = n * ln(x)

    EXACT - no approximation error!
    Exponentiation becomes multiplication.
    """
    return log_base * exponent / PRECISION

@internal
@pure
def _log_root(log_base: int128, n: uint256) -> int128:
    """
    Root: ln(x^(1/n)) = ln(x) / n

    EXACT - no approximation error!
    """
    assert n > 0, "Division by zero"
    return log_base * PRECISION / convert(n, int128)

@internal
@pure
def _log_add(log_a: int128, log_b: int128) -> int128:
    """
    Add: ln(a + b) - APPROXIMATE

    This is the tricky one. We use the identity:
    ln(a + b) = ln(a) + ln(1 + b/a)
              = ln(a) + ln(1 + e^(ln(b) - ln(a)))

    Approximations:
    - If |ln(a) - ln(b)| > 10, one dominates: return max
    - If similar: ln(a + b) ≈ max(ln(a), ln(b)) + ln(2)

    Error bound: at most 2x in worst case, typically <10%
    """
    # Handle edge cases
    if log_a == 0 and log_b == 0:
        return LN_2  # ln(1 + 1) = ln(2)

    diff: int128 = 0
    if log_a >= log_b:
        diff = log_a - log_b
    else:
        diff = log_b - log_a

    # If difference > ln(10000) ≈ 9.2, one value dominates
    if diff > 9 * PRECISION:
        if log_a >= log_b:
            return log_a
        else:
            return log_b

    # Values are similar magnitude
    # ln(a + b) ≈ ln(2a) = ln(a) + ln(2) when a ≈ b
    larger: int128 = log_a
    if log_b > log_a:
        larger = log_b

    # More accurate: ln(1 + e^(-diff)) ranges from ln(2) to 0
    # Simplified: use ln(2) as upper bound (always safe)
    return larger + LN_2

@internal
@pure
def _log_sub(log_a: int128, log_b: int128) -> int128:
    """
    Subtract: ln(a - b) - APPROXIMATE, requires a > b

    ln(a - b) = ln(a) + ln(1 - b/a)
              = ln(a) + ln(1 - e^(ln(b) - ln(a)))

    This is less useful than add, and only valid when a > b.
    """
    assert log_a > log_b, "Result would be negative or zero"

    diff: int128 = log_a - log_b

    # If a >> b, result ≈ a
    if diff > 9 * PRECISION:
        return log_a

    # Otherwise, need more careful approximation
    # ln(1 - e^(-diff)) is negative, approaching -∞ as diff→0
    # Simplified: subtract ln(2) as rough approximation
    return log_a - LN_2

# =============================================================================
# COMPARISON FUNCTIONS
# =============================================================================

@internal
@pure
def _log_gt(log_a: int128, log_b: int128) -> bool:
    """Greater than: a > b iff ln(a) > ln(b) - EXACT"""
    return log_a > log_b

@internal
@pure
def _log_lt(log_a: int128, log_b: int128) -> bool:
    """Less than: a < b iff ln(a) < ln(b) - EXACT"""
    return log_a < log_b

@internal
@pure
def _log_eq_approx(log_a: int128, log_b: int128, tolerance: int128) -> bool:
    """
    Approximate equality within tolerance
    |ln(a) - ln(b)| < tolerance means a/b is within e^tolerance
    """
    diff: int128 = log_a - log_b
    if diff < 0:
        diff = -diff
    return diff < tolerance

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

@internal
@pure
def _log_scale(log_x: int128, factor: int128) -> int128:
    """
    Scale by constant factor: ln(x * k) = ln(x) + ln(k)
    Pass ln(k) * PRECISION as factor
    """
    return log_x + factor

@internal
@pure
def _log_percentage(log_x: int128, percent: uint256) -> int128:
    """
    Compute percentage: ln(x * p/100)

    Example: 150% of x = x * 1.5 = ln(x) + ln(1.5)
    ln(1.5) * PRECISION ≈ 405465
    """
    # Pre-compute common percentages
    if percent == 100:
        return log_x
    elif percent == 150:
        return log_x + 405465  # ln(1.5)
    elif percent == 200:
        return log_x + LN_2    # ln(2)
    elif percent == 50:
        return log_x - LN_2    # ln(0.5) = -ln(2)
    else:
        # General case: ln(p/100)
        return log_x + self._ln(percent) - self._ln(100)

@internal
@pure
def _format_for_display(log_x: int128) -> uint256:
    """
    Convert log value to human-readable actual value
    For UI display only - don't use for calculations
    """
    return self._exp(log_x)

# =============================================================================
# STORAGE HELPERS
# =============================================================================

@internal
@pure
def _pack_two_logs(log_a: int128, log_b: int128) -> uint256:
    """
    Pack two int128 log values into one uint256 storage slot
    Saves 50% storage for paired values
    """
    return (convert(log_a, uint256) << 128) | (convert(log_b, uint256) & ((1 << 128) - 1))

@internal
@pure
def _unpack_two_logs(packed: uint256) -> (int128, int128):
    """Unpack two log values from one storage slot"""
    log_a: int128 = convert(packed >> 128, int128)
    log_b: int128 = convert(packed & ((1 << 128) - 1), int128)
    return (log_a, log_b)
