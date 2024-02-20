package attack

import "../../entities"
import "../../rng"
import rl "vendor:raylib"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "attack"
  capsule.description = "standard attack"
  capsule.texture = rl.LoadTexture("capital/resources/capsule.png")
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.active = true

  register_use(capsule, CapsuleUse(use))

  register_capsule(owner, capsule)

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities, rng

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    stats := get_statistics(source)
    response.value = roll(stats.level + 5, stats.strength * stats.strength_mul)
    if roll(100, 1) <= stats.critical_rate {
      set_flag(&response.flags, .CRITICAL)
      response.value *= 2
    }
  } else {
    set_flag(&response.flags, .MISS)
    response.value = 0
  }

  response.initial_value = response.value
  return response
}
