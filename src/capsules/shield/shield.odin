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
  capsule.default_target = .SELF
  capsule.priority = .HIGHER

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

  if source.shield == 0 {
    capsule := get_capsule_from_inventory(source, "shield")
    attach(source, capsule)
  }

  response.source = source
  response.target = source
  response.action = .DEFEND
  response.value = roll(source.level + 5, source.defense * source.defense_mul)

  source.shield += response.value

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities

  if message.action == .HURT {
    using message

    if .NODAMAGE not_in flags && .GUARDBREAK not_in flags {
      if target.shield > 0 {
        if value > target.shield {
          set_flag(&flags, .PARTIALBLOCK)
          value -= target.shield
          target.shield = 0
          set_flag(&flags, .DETACH)
        } else if value < target.shield {
          set_flag(&flags, .BLOCKED)
          target.shield -= value
          value = 0
        }
      }
    }

    if .GUARDBREAK in flags {
      target.shield = 0
      set_flag(&flags, .DETACH)
    }
  }
}
