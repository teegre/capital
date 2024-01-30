package attack

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "attack"
  capsule.description = "standard attack"
  capsule.active = true
  register_use(capsule, CapsuleUse(use))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }
  return true
}

use :: proc(source, target: ^entities.Character) -> (dmg: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities, rng
  action = .ATTACK
  set_flag(&flags, .ATTACK)

  if success(source, target) {
    dmg = roll(source.level + 5, source.strength * source.strength_mul)
    if roll(100, 1) <= source.critical_rate {
      set_flag(&flags, .CRITICAL)
      dmg *= 2
    }
  } else {
    set_flag(&flags, .MISS)
    return 0, action, flags
  }

  return dmg, action, flags
}
