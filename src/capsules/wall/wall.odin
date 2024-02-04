package wall

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "wall"
  capsule.description = "safe... temporarly"
  capsule.active = true
  capsule.owner = owner
  capsule.default_target = .SELF
  capsule.priority = .HIGHEST

  register_use(capsule, CapsuleUse(use))
  register_effect(capsule, CapsuleEffect(effect))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }
  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities

  capsule := get_capsule_from_inventory(source, "wall")
  attach(source, capsule)

  response.source = source
  response.target = source
  response.action = .DEFEND

  capsule.active = false

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities, message

  if action == .HURT && value > 0 {
    capsule := get_active_capsule(target, "wall")
    set_flag(&flags, .NODAMAGE)
    set_flag(&flags, .DETACH)
    capsule.active = true
    value = 0
    message.action = .NONE
  }
}
