package leech

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "leech"
  capsule.description = "energy drain"
  capsule.active = true
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.priority = .LOWEST

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

  capsule := get_capsule_from_inventory(source, "leech")
  attach(target, capsule)

  capsule.active = false

  response.source = source
  response.target = target
  response.action = .NONE

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities

  if message.action == .HURT && message.value > 0 {
    heal(message.source, message.value)
    set_flag(&message.flags, .HEAL)
  }
}
