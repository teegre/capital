package attack

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "attack"
  capsule.description = "standard attack"
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.active = true

  register_use(capsule, CapsuleUse(use))

  // FIXME: Check inventory capacity first, and then create capsule.
  // Valid in all capsules source code.
  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities, rng

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    response.value = roll(source.level + 5, source.strength * source.strength_mul)
    if roll(100, 1) <= source.critical_rate {
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
