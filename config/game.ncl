# MegaDog Game Configuration (Nickel)
# Economic parameters, fractal settings, and game balance

let GameEconomy = {
  # Logarithmic precision (ln(x) * PRECISION)
  log_precision | Number,

  # Starting values
  starter_treats | Number,        # Actual treats for new dog
  starter_log_treats | Number,    # ln(starter_treats) * precision

  # Progression
  merge_bonus_multiplier | Number,
  passive_income_rate | Number,   # Treats per second per level
  prestige_threshold_level | Number,

  # Rarity
  rare_dog_probability | Number,
  bonus_dog_count | Number,
}

let FractalConfig = {
  # Mandelbulb parameters
  default_iterations | Number,
  max_iterations | Number,
  bailout_radius | Number,
  power | Number,  # Mandelbulb power (8 = classic)

  # Rendering
  resolution_mobile | { width | Number, height | Number },
  resolution_nft | { width | Number, height | Number },

  # Ray marching
  max_ray_steps | Number,
  ray_epsilon | Number,
}

let AntiCheat = {
  max_actions_per_minute | Number,
  max_merges_per_hour | Number,
  suspicious_pattern_threshold | Number,
  cooldown_seconds | Number,
}

in {
  economy | GameEconomy = {
    log_precision = 1000000,

    starter_treats = 100,
    starter_log_treats = 4605170,  # ln(100) * 10^6

    merge_bonus_multiplier = 1.5,
    passive_income_rate = 0.1,
    prestige_threshold_level = 50,

    rare_dog_probability = 0.001,
    bonus_dog_count = 10000,
  },

  fractal | FractalConfig = {
    default_iterations = 12,
    max_iterations = 256,
    bailout_radius = 2.0,
    power = 8.0,

    resolution_mobile = { width = 1080, height = 1920 },
    resolution_nft = { width = 2048, height = 2048 },

    max_ray_steps = 128,
    ray_epsilon = 0.001,
  },

  anti_cheat | AntiCheat = {
    max_actions_per_minute = 60,
    max_merges_per_hour = 500,
    suspicious_pattern_threshold = 0.95,
    cooldown_seconds = 5,
  },

  # Transparency settings (anti-scam)
  transparency = {
    show_real_costs = true,
    show_odds = true,
    no_fake_money_claims = true,
    open_source = true,

    disclaimer = m%"
      MegaDog is a GAME, not a money-making scheme.
      - You will NOT earn real money
      - Your dogs are NFTs you actually own
      - All odds and mechanics are public
      - This is math, not magic
    "%,
  },
}
