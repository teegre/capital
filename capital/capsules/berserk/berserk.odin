package berserk

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  // if len(owner.inventory) == owner.max_items {
  //   return false
  // }

  using entities

  capsule := new(Capsule)
  capsule.name = "berserk"
  capsule.description = "powerful and painless"
  capsule.owner = owner
  capsule.default_target = .SELF
  capsule.active = true
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

  response.source = source
  response.target = target
  response.action = .BUFF

  capsule := get_capsule_from_inventory(source, "berserk")
  attach(source, capsule)

  capsule.active = false

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities
  if message.action == .ATTACK {
    message.value *= 2
  }
  if message.action == .HURT {
    set_flag(&message.flags, .NOPAIN)
  }
}
