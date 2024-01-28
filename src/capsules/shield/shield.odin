package shield

import "../../entities"
import "../../rng"

use :: proc(source, target: ^entities.Character) -> (data: int, flags: entities.CapsuleFlags) {
  using entities
  incl_elem(&flags, CapsuleFlag.DEFEND)
  data = rng.roll(source.level + 5, source.defense * source.defense_mul)
  source.shield += data
  return data, flags
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
