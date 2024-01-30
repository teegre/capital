package leech

import "core:fmt"
import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "leech"
  capsule.description = "energy drain"
  capsule.active = true
  capsule.owner = owner
  register_use(capsule, CapsuleUse(use))
  register_effect(capsule, CapsuleEffect(effect))
  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }
  return true
}

use :: proc(source, target: ^entities.Character) -> (value: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities
  capsule := get_capsule_from_inventory(source, "leech")
  attach(target, capsule)
  capsule.active = false
  set_flag(&flags, .ATTACHED)
  return 0, .ATTACH, flags
}

effect :: proc(source, target:  ^entities.Character, action: entities.CapsuleEventName, initial: int) -> (value: int, flags: entities.CapsuleFlags) {
  if action == .HURT {
    hit := 0
      if initial > source.shield {
        hit = initial - source.shield
      } else if initial <= source.shield {
        hit = 0
      }
      if hit > 0 {
        entities.heal(target, hit)
      }
  }
  return initial, flags
}
