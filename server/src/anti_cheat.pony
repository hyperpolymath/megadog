"""
MegaDog Anti-Cheat Engine
Prevents bot farming and exploitation
"""

use "collections"
use "time"

actor AntiCheatEngine
  """
  Validates player actions to prevent:
  - Bot farming (automated merging)
  - Timing exploits
  - Suspicious patterns

  Uses rate limiting and pattern analysis
  """
  let _env: Env
  let _config: GameConfig val
  var _user_sessions: Map[String, UserSession]

  new create(env: Env, config: GameConfig val) =>
    _env = env
    _config = config
    _user_sessions = Map[String, UserSession]

  be validate_action(
    user_id: String,
    action: ActionType,
    callback: {((Bool, String))} val
  ) =>
    """
    Validate if an action should be allowed
    Returns (allowed, reason)
    """
    let session = _get_or_create_session(user_id)
    let now = Time.nanos()

    // Check rate limits
    match action
    | ActionMerge =>
      if not session.can_merge(now, _config) then
        callback((false, "Merge rate limit exceeded"))
        return
      end
    | ActionMint =>
      if not session.can_mint(now, _config) then
        callback((false, "Mint rate limit exceeded"))
        return
      end
    | ActionPrestige =>
      if not session.can_prestige(now, _config) then
        callback((false, "Prestige rate limit exceeded"))
        return
      end
    end

    // Check for bot patterns
    if session.is_suspicious(_config) then
      _env.out.print("Suspicious activity detected for user: " + user_id)
      callback((false, "Suspicious activity detected"))
      return
    end

    // Record action
    session.record_action(action, now)
    _user_sessions(user_id) = session

    callback((true, "OK"))

  be reset_user(user_id: String) =>
    """Reset a user's session (for testing or appeals)"""
    try
      _user_sessions.remove(user_id)?
      _env.out.print("Reset session for user: " + user_id)
    end

  be get_user_stats(user_id: String, callback: {((USize, USize, F64))} val) =>
    """Get user statistics: (actions_last_minute, merges_last_hour, suspicion_score)"""
    try
      let session = _user_sessions(user_id)?
      let now = Time.nanos()
      callback((
        session.actions_in_window(now, 60_000_000_000),  // 1 minute
        session.merges_in_window(now, 3_600_000_000_000), // 1 hour
        session.suspicion_score()
      ))
    else
      callback((0, 0, 0.0))
    end

  fun ref _get_or_create_session(user_id: String): UserSession =>
    try
      _user_sessions(user_id)?
    else
      let session = UserSession.create()
      _user_sessions(user_id) = session
      session
    end


primitive ActionMerge
primitive ActionMint
primitive ActionPrestige

type ActionType is (ActionMerge | ActionMint | ActionPrestige)


class UserSession
  """
  Tracks a user's recent activity for anti-cheat purposes
  """
  var _action_times: Array[U64]
  var _merge_times: Array[U64]
  var _action_intervals: Array[U64]
  var _last_action_time: U64

  new create() =>
    _action_times = Array[U64]
    _merge_times = Array[U64]
    _action_intervals = Array[U64]
    _last_action_time = 0

  fun ref record_action(action: ActionType, timestamp: U64) =>
    """Record an action timestamp"""
    // Record interval since last action
    if _last_action_time > 0 then
      _action_intervals.push(timestamp - _last_action_time)
      // Keep last 100 intervals
      if _action_intervals.size() > 100 then
        try _action_intervals.shift()? end
      end
    end

    _action_times.push(timestamp)
    _last_action_time = timestamp

    // Keep last 1000 actions
    if _action_times.size() > 1000 then
      try _action_times.shift()? end
    end

    match action
    | ActionMerge =>
      _merge_times.push(timestamp)
      if _merge_times.size() > 1000 then
        try _merge_times.shift()? end
      end
    end

  fun can_merge(now: U64, config: GameConfig val): Bool =>
    """Check if merge is allowed based on rate limit"""
    let merges_last_hour = merges_in_window(now, 3_600_000_000_000)
    merges_last_hour < config.max_merges_per_hour.usize()

  fun can_mint(now: U64, config: GameConfig val): Bool =>
    """Check if mint is allowed"""
    // Allow one mint per user (starter dog)
    // In production, check blockchain for existing dogs
    true

  fun can_prestige(now: U64, config: GameConfig val): Bool =>
    """Check if prestige is allowed"""
    // Cooldown between prestiges
    let actions = actions_in_window(now, config.cooldown_seconds.u64() * 1_000_000_000)
    actions < 2

  fun actions_in_window(now: U64, window_ns: U64): USize =>
    """Count actions within time window"""
    var count: USize = 0
    let cutoff = now - window_ns
    for t in _action_times.values() do
      if t > cutoff then
        count = count + 1
      end
    end
    count

  fun merges_in_window(now: U64, window_ns: U64): USize =>
    """Count merges within time window"""
    var count: USize = 0
    let cutoff = now - window_ns
    for t in _merge_times.values() do
      if t > cutoff then
        count = count + 1
      end
    end
    count

  fun is_suspicious(config: GameConfig val): Bool =>
    """
    Detect bot-like patterns:
    - Too-regular intervals (bots are precise)
    - Inhuman speed
    - Statistical anomalies
    """
    suspicion_score() > config.suspicious_pattern_threshold.f64()

  fun suspicion_score(): F64 =>
    """
    Calculate suspicion score (0.0 - 1.0)
    Higher = more likely to be a bot
    """
    if _action_intervals.size() < 10 then
      return 0.0  // Not enough data
    end

    // Calculate coefficient of variation in action intervals
    // Bots have very low variation (too consistent)
    var sum: U64 = 0
    var count: USize = 0
    for interval in _action_intervals.values() do
      sum = sum + interval
      count = count + 1
    end

    if count == 0 then
      return 0.0
    end

    let mean = sum.f64() / count.f64()
    if mean == 0.0 then
      return 0.0
    end

    // Calculate standard deviation
    var variance_sum: F64 = 0.0
    for interval in _action_intervals.values() do
      let diff = interval.f64() - mean
      variance_sum = variance_sum + (diff * diff)
    end

    let std_dev = (variance_sum / count.f64()).sqrt()
    let cv = std_dev / mean  // Coefficient of variation

    // Low CV = suspicious (too consistent)
    // Human behavior has CV around 0.3-0.7
    // Bots often have CV < 0.1
    if cv < 0.1 then
      0.9  // Very suspicious
    elseif cv < 0.2 then
      0.6  // Somewhat suspicious
    elseif cv < 0.3 then
      0.3  // Slightly suspicious
    else
      0.0  // Normal human variation
    end
