package steroids

import "../../entities"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  if len(owner.inventory) == owner.max_items {
    return false
  }

  using entities

  capsule := new(Capsule)
  capsule.name = "steroids"
  capsule.description = "you feel stronger"
  capsule.active = true
  capsule.owner = owner
  capsule.default_target = .SELF
  capsule.priority = .LOWEST

  register_use(capsule, CapsuleUse(use))
  register_on_detach(capsule, CapsuleOnDetach(on_detach))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities

  capsule := get_capsule_from_inventory(source, "steroids")
  attach(source, capsule)

  capsule.active = false
  capsule.value = source.strength_mul
  source.strength_mul *= 2

  response.source = source
  response.target = target
  response.action = .BUFF

  return response
}

on_detach :: proc(target: ^entities.Character) {
  using entities
  capsule := get_active_capsule(target, "steroids")
  target.strength_mul = capsule.value
  capsule.active = true
}
