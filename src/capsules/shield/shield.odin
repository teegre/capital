package shield

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "shield"
  capsule.description = "standard shield"
  capsule.active = true
  capsule.owner = owner
  register_use(capsule, CapsuleUse(use))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }

  return true
}

use :: proc(source, target: ^entities.Character) -> (data: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities
  action = .DEFEND
  data = rng.roll(source.level + 5, source.defense * source.defense_mul)
  source.shield += data
  return data, action, flags
}

