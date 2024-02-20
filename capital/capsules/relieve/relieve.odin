package relieve

import "../../entities"
import "../../rng"
import rl "vendor:raylib"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "relieve"
  capsule.description = "relieve the pain"
  capsule.texture = rl.LoadTexture("capital/resources/capsule.png")
  capsule.owner = owner
  capsule.default_target = .OTHER
  capsule.active = false

  register_use(capsule, CapsuleUse(use))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }

  return true
}

use :: proc(source, target: ^entities.Character) -> (response: entities.Response) {
  using entities, rng

  stats := get_statistics(source)

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    response.value = roll(stats.level + 5, stats.strength * stats.strength_mul)
    if roll(100, 1) <= stats.critical_rate {
      set_flag(&response.flags, .CRITICAL)
      response.value *= 2
    }
    response.value *= stats.pain_rate / 100
  } else {
    set_flag(&response.flags, .MISS)
    return response
  }
  
  heal(source)
  set_flag(&response.flags, .HEAL)
  stats.pain = 0
  stats.pain_rate = 0
  deactivate(source, "relieve")

  return response
}
