package shield

import "../../entities"
import "../../rng"
import rl "vendor:raylib"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "shield"
  capsule.description = "standard shield"
  capsule.texture = rl.LoadTexture("capital/resources/capsule.png")
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

  stats := get_statistics(source)

  if stats.shield == 0 {
    capsule := get_capsule_from_inventory(source, "shield")
    attach(source, capsule)
  }

  response.source = source
  response.target = source
  response.action = .DEFEND
  response.value = roll(stats.level + 5, stats.defense * stats.defense_mul)

  stats.shield += response.value

  return response
}

effect :: proc(message: ^entities.Response) {
  using entities

  if message.action == .HURT {
    using message
    stats := get_statistics(target)

    if .NODAMAGE not_in flags && .GUARDBREAK not_in flags {
      if stats.shield > 0 {
        if value > stats.shield {
          set_flag(&flags, .PARTIALBLOCK)
          value -= stats.shield
          stats.shield = 0
          set_flag(&flags, .DETACH)
        } else if value < stats.shield {
          set_flag(&flags, .BLOCKED)
          stats.shield -= value
          value = 0
        }
      }
    }

    if .GUARDBREAK in flags {
      stats.shield = 0
      set_flag(&flags, .DETACH)
    }
  }
}
