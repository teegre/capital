package relieve

import "../../entities"
import "../../rng"

new_capsule :: proc() -> ^entities.Capsule {
  using entities
  capsule := new(Capsule)
  capsule.name = "relieve"
  capsule.description = "relieve the pain"
  capsule.active = false
  register_use(capsule, CapsuleUse(use))
  return capsule
}

use :: proc(source, target: ^entities.Character) -> (data: int, flags: entities.CapsuleFlags) {
  using entities, rng
  set_flag(&flags, .ATTACK)

  if success(source, target) {
    data = roll(source.level + 5, source.strength * source.strength_mul)
    if roll(100, 1) <= source.critical_rate {
      set_flag(&flags, .CRITICAL)
      data *= 2
    }
    data *= source.pain_rate / 100
  } else {
    set_flag(&flags, .MISS)
    return 0, flags
  }
  
  heal(source)
  source.pain = 0
  source.pain_rate = 0
  deactivate(source, "relieve")

  return data, flags
}
