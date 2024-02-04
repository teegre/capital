package berserk

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  if len(owner.inventory) == owner.max_items {
    return false
  }

  using entities

  capsule := new(Capsule)
  capsule.name = "berserk"
  capsule.description = "powerful and painless"
  capsule.owner = owner
  capsule.default_target = .SELF
  capsule.active = true

  register_use(capsule, CapsuleUse(use))
  register_effect(capsule, CapsuleEffect(effect))

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities

  response.source = source
  response.target = target
  response.action = .NONE

  capsule := get_capsule_from_inventory(source, "berserk")
  attach(source, capsule)
  capsule.active = false

  return response
}

effect :: proc(message: ^entities.Response) {
  if message.action == .ATTACK {
    message.value *= 2
  }
}
