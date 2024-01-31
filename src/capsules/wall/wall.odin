package wall

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "wall"
  capsule.description = "safe... temporarly"
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
  capsule := get_capsule_from_inventory(source, "wall")
  attach(source, capsule)
  capsule.active = false
  set_flag(&flags, .ATTACHED)
  return 0, .ATTACH, flags
}

effect :: proc(source, target: ^entities.Character, action: entities.CapsuleEventName, initial: int) -> (value: int, flags: entities.CapsuleFlags) {
  using entities
  if action == .HURT {
    capsule := get_active_capsule(source, "wall")
    capsule.active = true
    detach(source, "wall")
    set_flag(&flags, .NODAMAGE)
  }
  return initial, flags
}
