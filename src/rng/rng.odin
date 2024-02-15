package rng

import "core:math"
import "core:math/rand"
import "core:text/match"
import "core:strings"
import "core:slice"
import "../entities"

SEED: string
@(private)
U_SEED: u64
@(private)
CAPSULE_RNG: rand.Rand
@(private)
ROLL_RNG: rand.Rand
@(private)
ACTION_RNG: rand.Rand
@(private)
CHEST_RNG: rand.Rand

check_seed :: proc(seed: string) -> bool {
  /* Check if seed is legit. */
  if len(seed) != 8 {
    return false
  }

  for c in seed {
    if !match.is_alnum(c) {
      return false
    }
  }
  
  return true
}

convert_seed :: proc(seed: string) -> u64 {
  /* Convert a seed (string) to a u64 integer. */
  n_seed: u64 = 0
  u_seed: []u8 = transmute([]u8)seed
  p : f64 = 14

  for n in u_seed[:] {
    n_seed += cast(u64)n * cast(u64)math.pow10_f64(p)
    p -= 2
  }

  return n_seed
}

new_seed :: proc() -> ( string, u64 ) {
  /*
    Generate a reusable seed for random number generators.
    ^[A-Z0-9]{8}$
  */
  s: strings.Builder
  chars : []string = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "0","1","2","3","4","5","6","7","8","9"}

  defer strings.builder_destroy(&s)
  defer delete_slice(chars[:])

  for _ in 0..<8 {
     strings.write_string(&s, rand.choice(chars[:]))
  }

  seed : string = strings.to_string(s)
  return seed, convert_seed(seed)
}

set_seed :: proc(seed: string = "") {
  /* 
    Create random number generators with a given seed
    or a randomly generated one.
  */
  if seed != "" {
    SEED = seed
    U_SEED = convert_seed(SEED)
  } else {
    SEED, U_SEED = new_seed()
  }
  CAPSULE_RNG = rand.create(U_SEED)
  ROLL_RNG = rand.create(U_SEED + 1)
  ACTION_RNG = rand.create(U_SEED + 2)
  CHEST_RNG = rand.create(U_SEED + 3)
}

roll :: proc(s: int = 6, n: int = 2) -> ( sum: int ) {
  /* 
    Roll the dice.
    s: sides, n: dice.
  */
  for i in 0..<n {
    sum += rand.int_max(s, &ROLL_RNG) + 1
  }

  return sum
}

success :: proc(source, target: ^entities.Character) -> bool {
  /*
    Return true if source's roll is greater than target's roll.
  */
  source_sum : int = 0
  target_sum : int = 0

  for source_sum == target_sum {
    source_sum = roll(6, 2)
    target_sum = roll(6, 2)
    source_sum += source.agility
    target_sum += target.agility
  }

  return source_sum > target_sum
}

choice :: proc(actions: [dynamic]string) -> string {
  return rand.choice(actions[:], &ACTION_RNG)
}
