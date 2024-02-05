package deflector

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  if len(owner.inventory) == owner.max_items {
    return false
  }

  using entities

  capsule := new(Capsule)
  capsule.name = "deflector"
  capsule.description = "return to sender"
  capsule.active = true
  capsule.owner = owner
  capsule.default_target = .SELF
  capsule.priority =  .HIGHEST

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

  capsule := get_capsule_from_inventory(source, "deflector")
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
    activate(message.target, "deflector")
    source := message.source
    target := message.target
    message.source = target
    message.target = source
    message.action = .ATTACK
    set_flag(&message.flags, .DETACH)
    set_flag(&message.flags, .IGNORE)
  }
}
