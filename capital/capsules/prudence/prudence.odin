package prudence

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities

  capsule := new(Capsule)
  capsule.name = "prudence"
  capsule.description = "the best form of defence"
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.active = true
  capsule.priority = .LOWEST

  register_use(capsule, CapsuleUse(use))
  register_effect(capsule, CapsuleEffect(effect))

  register_capsule(owner, capsule)

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities, rng

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    stats := get_statistics(source)
    response.value = roll(stats.level + 5, stats.strength * stats.strength_mul)
    if roll(100, 1) <= stats.critical_rate {
      set_flag(&response.flags, .CRITICAL)
      response.value *= 2
    }
    if !is_attached(target, "prudence") {
      capsule := get_capsule_from_inventory(source, "prudence")
      attach(target, capsule)
    }    
  } else {
    set_flag(&response.flags, .MISS)
    response.value = 0
  }

  response.initial_value = response.value
  return response
}

effect :: proc(message: ^entities.Response) {
  using entities

  if message.action == .HURT && message.value > 0 {
    using message
    stats := get_statistics(source)

    if stats.shield == 0 {
      set_flag(&flags, .PROTECT)
    }

    set_flag(&flags, .DETACH)
    stats.shield += value
  }
}
