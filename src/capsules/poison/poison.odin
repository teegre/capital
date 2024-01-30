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
  register_use(capsule, CapsuleUse(use))
  register_effect(capsule, CapsuleEffect(effect))

  if !register_capsule(owner, capsule) {
    free(capsule)
    return false
  }
  return true
}

use :: proc(source, target: ^entities.Character) -> (value: int, action: entities.CapsuleEventName, flags: entities.CapsuleFlags) {
  using entities, rng
  capsule := get_capsule_from_inventory(source, "poison")
  attach(target, capsule)
  capsule.active = false
  set_flag(&flags, .ATTACHED)
  value = roll(source.level + 5, source.level)
  capsule.value = value
  return value, .ATTACH, flags
}

effect :: proc(source, target: ^entities.Character, action: entities.CapsuleEventName, initial: int) -> (value: int, flags: entities.CapsuleFlags) {
  using entities

  capsule := get_active_capsule(source, "poison")

  source.health -= capsule.value
  source.pain += capsule.value
  source.pain_rate = source.pain * 100 / source.health

  if source.health <= 0 {
    set_flag(&flags, .DEAD)
    detach(source, "poison")
    activate(capsule.owner, "poison")
    source.health = 0
    return initial, flags
  }

  capsule.value -= 1

  if capsule.value <= 0 {
    capsule.value = 0
    value = 0
    detach(source, "poison")
    activate(capsule.owner, "poison")
    set_flag(&flags, .NOEFFECT)
  }

  return initial, flags
}
