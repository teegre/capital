package attack

import "../../entities"
import "../../rng"

new_capsule :: proc() -> ^entities.Capsule {
  using entities
  capsule := new(Capsule)
  capsule.name = "attack"
  capsule.description = "standard attack"
  capsule.active = true
  register_use(capsule, CapsuleUse(use))
  return capsule
}

use :: proc(source, target: ^entities.Character) -> (dmg: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities, rng
  action = .ATTACK

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
