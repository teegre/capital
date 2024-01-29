package actions

import "../entities"

perform_action :: proc(source, target: ^entities.Character, capsule_name: string) ->  (value: int, flags: entities.CapsuleFlags) {
  using entities

  capsule := get_capsule_from_inventory(source, capsule_name)
  if capsule == nil {
    set_flag(&flags, .NOCAPSULE)
    return 0, flags
  }

  initial_value: int
  action: entities.CapsuleEventName
  initial_value, action, flags = capsule.use(source, target)

  // SOURCE → PASSIVE CAPSULE EFFECTS HERE
  effect_value, effect_flags := apply_passive_capsule_effects(source, target, action, initial_value)
  initial_value = effect_value
  flags += effect_flags

  if action == .ATTACK && .MISS not_in flags {
    // TARGET → PASSIVE CAPSULE EFFECTS HERE
    effect_value, effect_flags = apply_passive_capsule_effects(target, source, action, initial_value)
    initial_value = effect_value
    flags += effect_flags

    value, hurt_flags := hurt(source, target, initial_value)

    return value, flags + hurt_flags
  }
  value = initial_value
  return value, flags
}

apply_passive_capsule_effects :: proc(source, target: ^entities.Character, action: entities.CapsuleEventName, initial: int) -> (value: int, flags: entities.CapsuleFlags) {
  initial_value := initial
  initial_flags: entities.CapsuleFlags

  for capsule in source.active_capsules {
    if capsule.effect != nil {
       value, initial_flags = capsule.effect(source, target, action, initial_value)
       initial_value = value
       flags += initial_flags
    }
  }
  value = initial_value
  return value, flags
}
