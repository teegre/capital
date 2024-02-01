package relieve

import "../../entities"
import "../../rng"

new_capsule :: proc(owner: ^entities.Character) -> bool {
  using entities
  capsule := new(Capsule)
  capsule.name = "relieve"
  capsule.description = "relieve the pain"
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

  response.source = source
  response.target = target
  response.action = .ATTACK

  if success(source, target) {
    response.value = roll(source.level + 5, source.strength * source.strength_mul)
    if roll(100, 1) <= source.critical_rate {
      set_flag(&response.flags, .CRITICAL)
      response.value *= 2
    }
    response.value *= source.pain_rate / 100
  } else {
    set_flag(&response.flags, .MISS)
    return response
  }
  
  heal(source)
  source.pain = 0
  source.pain_rate = 0
  deactivate(source, "relieve")

  return response
}
