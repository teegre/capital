package poison

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "poison"
  capsule.description = "slow death"
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
  using entities, rng

  capsule := get_capsule_from_inventory(source, "poison")
  attach(target, capsule)

  capsule.active = false

  response.source = source
  response.target = target
  response.action = .NONE
  response.value = roll(source.level + 5, source.level)

  capsule.value = response.value

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities

  if message.action == .HURT || message.action == .NONE {
    return
  }

  using message

  capsule := get_active_capsule(source, "poison")

  flag := hurt_direct(source, capsule.value, .NOPAIN not_in flags)

  if flag == .DEAD {
    set_flag(&flags, flag)
    set_flag(&flags, .DETACH)
    activate(capsule.owner, "poison")
    return
  }

  capsule.value -= 1

  if capsule.value <= 0 {
    capsule.value = 0
    value = 0
    set_flag(&flags, .DETACH)
    activate(capsule.owner, "poison")
  }
}
