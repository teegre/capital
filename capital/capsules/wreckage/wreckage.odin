package wreckage

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  // if len(owner.inventory) == owner.max_items {
  //   return false
  // }

  capsule := new(Capsule)
  capsule.name = "wreckage"
  capsule.description = "break it!"
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.active = true

  register_use(capsule, CapsuleUse(use))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities, rng

  stats := get_statistics(source)

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    response.value = roll(stats.level + 5, stats.strength * stats.strength_mul)
    if roll(100, 1) <= stats.critical_rate {
      set_flag(&response.flags, .CRITICAL)
      response.value *= 2
    }
    set_flag(&response.flags, .GUARDBREAK)
  } else {
    set_flag(&response.flags, .MISS)
    response.value = 0
  }

  response.initial_value = response.value
  return response
}
