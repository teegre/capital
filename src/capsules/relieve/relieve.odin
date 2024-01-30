package relieve

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "relieve"
  capsule.description = "relieve the pain"
  capsule.active = false
  capsule.owner = owner
  register_use(capsule, CapsuleUse(use))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }
  return true
}

use :: proc(source, target: ^entities.Character) -> (data: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities, rng
  action = .ATTACK

  if success(source, target) {
    data = roll(source.level + 5, source.strength * source.strength_mul)
    if roll(100, 1) <= source.critical_rate {
      set_flag(&flags, .CRITICAL)
      data *= 2
    }
    data *= source.pain_rate / 100
  } else {
    set_flag(&flags, .MISS)
    return 0, action, flags
  }
  
  heal(source)
  source.pain = 0
  source.pain_rate = 0
  deactivate(source, "relieve")

  return data, action, flags
}
