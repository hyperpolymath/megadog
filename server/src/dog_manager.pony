"""
MegaDog State Manager Actor
Handles all dog operations with actor isolation
"""

use "collections"
use "time"

actor DogStateManager
  """
  Central actor for dog state management
  All mutations go through here for consistency
  """
  let _env: Env
  let _config: GameConfig val
  var _dogs: Map[U256, Dog val]
  var _user_dogs: Map[String, Array[U256]]  // owner -> dog IDs
  var _next_dog_id: U256
  var _current_block: U64

  new create(env: Env, config: GameConfig val) =>
    _env = env
    _config = config
    _dogs = Map[U256, Dog val]
    _user_dogs = Map[String, Array[U256]]
    _next_dog_id = 1
    _current_block = 0

  be set_current_block(block: U64) =>
    """Update current block number (called by blockchain monitor)"""
    _current_block = block

  be mint_starter_dog(owner: String, callback: {(Dog val)} val) =>
    """Mint a new level-1 starter dog for a player"""
    let dog_id = _next_dog_id
    _next_dog_id = _next_dog_id + 1

    let seed = FractalSeed.generate(dog_id, owner, _current_block)
    let dog = Dog.starter(dog_id, owner, seed, _current_block)

    _dogs(dog_id) = dog

    // Add to user's dog list
    try
      _user_dogs(owner)?.push(dog_id)
    else
      let dogs = Array[U256]
      dogs.push(dog_id)
      _user_dogs(owner) = dogs
    end

    _env.out.print("Minted dog #" + dog_id.string() + " for " + owner)
    callback(dog)

  be merge_dogs(
    owner: String,
    dog1_id: U256,
    dog2_id: U256,
    callback: {((Dog val | MergeError))} val
  ) =>
    """
    Merge two same-level dogs into a higher-level dog
    THE MILKSHAKE BLENDER OPERATION
    """
    try
      let dog1 = _dogs(dog1_id)?
      let dog2 = _dogs(dog2_id)?

      // Validation
      if dog1.owner != owner then
        callback(MergeError.not_owner())
        return
      end
      if dog2.owner != owner then
        callback(MergeError.not_owner())
        return
      end
      if dog1.level != dog2.level then
        callback(MergeError.level_mismatch())
        return
      end
      if dog1.level >= 255 then
        callback(MergeError.max_level())
        return
      end

      // Create merged dog
      let new_dog_id = _next_dog_id
      _next_dog_id = _next_dog_id + 1

      let new_seed = FractalSeed.merge(dog1.fractal_seed, dog2.fractal_seed, _current_block)
      let combined_treats = LogMath.add_logs(
        dog1.log_treats,
        dog2.log_treats,
        _config.log_precision
      )
      let combined_merges = LogMath.add_logs(
        dog1.log_merge_count,
        dog2.log_merge_count,
        _config.log_precision
      )

      let new_dog = Dog.create(
        new_dog_id,
        owner,
        dog1.level + 1,
        combined_treats,
        combined_merges + 693147,  // Add ln(2) for the merge itself
        new_seed,
        _current_block,
        _current_block
      )

      // Remove old dogs (they explode into hearts!)
      _dogs.remove(dog1_id)?
      _dogs.remove(dog2_id)?

      // Add new dog
      _dogs(new_dog_id) = new_dog

      // Update user's dog list
      try
        let user_dogs = _user_dogs(owner)?
        // Remove old IDs
        let new_list = Array[U256]
        for id in user_dogs.values() do
          if (id != dog1_id) and (id != dog2_id) then
            new_list.push(id)
          end
        end
        new_list.push(new_dog_id)
        _user_dogs(owner) = new_list
      end

      _env.out.print("Merged dogs #" + dog1_id.string() + " + #" + dog2_id.string()
        + " -> #" + new_dog_id.string() + " (level " + new_dog.level.string() + ")")

      callback(new_dog)
    else
      callback(MergeError.dog_not_found())
    end

  be get_dog(dog_id: U256, callback: {((Dog val | None))} val) =>
    """Get a dog by ID"""
    try
      callback(_dogs(dog_id)?)
    else
      callback(None)
    end

  be get_user_dogs(owner: String, callback: {(Array[Dog val] val)} val) =>
    """Get all dogs owned by a user"""
    let result = recover val
      let dogs = Array[Dog val]
      try
        let dog_ids = _user_dogs(owner)?
        for id in dog_ids.values() do
          try
            dogs.push(_dogs(id)?)
          end
        end
      end
      dogs
    end
    callback(result)

  be prestige_reset(
    owner: String,
    top_dog_id: U256,
    callback: {((Dog val | PrestigeError))} val
  ) =>
    """
    MILKSHAKE BLENDER RECONSTITUTION
    Reset to level 1 with permanent bonus
    """
    try
      let dog = _dogs(top_dog_id)?

      if dog.owner != owner then
        callback(PrestigeError.not_owner())
        return
      end

      if dog.level < _config.prestige_threshold then
        callback(PrestigeError.level_too_low())
        return
      end

      // Calculate prestige bonus: ln(multiplier) = level / 10
      let prestige_bonus = (dog.level.i128() * _config.log_precision) / 10

      // Generate new fractal seed (the blender reconstitutes!)
      let new_seed = FractalSeed.generate(dog.id, owner, _current_block)

      let prestiged_dog = Dog.create(
        dog.id,
        owner,
        1,  // Reset to level 1
        _config.starter_log_treats + prestige_bonus,
        dog.log_merge_count,
        new_seed,
        dog.birth_block,
        _current_block
      )

      _dogs(dog.id) = prestiged_dog

      _env.out.print("Prestige reset for dog #" + dog.id.string()
        + " (was level " + dog.level.string() + ", bonus: "
        + prestige_bonus.string() + ")")

      callback(prestiged_dog)
    else
      callback(PrestigeError.dog_not_found())
    end

  be get_stats(callback: {((USize, USize, U256))} val) =>
    """Get server statistics: (total_dogs, total_users, next_dog_id)"""
    callback((_dogs.size(), _user_dogs.size(), _next_dog_id))


class val MergeError
  let message: String

  new val not_owner() => message = "You don't own this dog"
  new val level_mismatch() => message = "Dogs must be the same level"
  new val max_level() => message = "Dog is already max level"
  new val dog_not_found() => message = "Dog not found"


class val PrestigeError
  let message: String

  new val not_owner() => message = "You don't own this dog"
  new val level_too_low() => message = "Dog must reach level 50 to prestige"
  new val dog_not_found() => message = "Dog not found"
