package shield

import "../../entities"
import "../../rng"

use :: proc(source, target: ^entities.Character) -> (data: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities
  action = .DEFEND
  data = rng.roll(source.level + 5, source.defense * source.defense_mul)
  source.shield += data
  return data, action, flags
}

new_capsule :: proc() -> ^entities.Capsule {
  using entities
  capsule := new(Capsule)
  capsule.name = "shield"
  capsule.description = "standard shield"
  capsule.active = true
  register_use(capsule, CapsuleUse(use))
  return capsule
}
