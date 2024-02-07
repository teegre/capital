package entities

// A capsule
Capsule :: struct {
  name: string,
  description: string,
  active: bool, // if active, capsule can be listed as an action for the owner.
  owner: ^Character,
  default_target: CapsuleTarget, // default target may be self or other.
  auto: bool, // if true, attached when starting a fight.
  value: int, // optional value used internally.
  priority: Priority, // priority for effect triggering.
  use: CapsuleUse, // mandatory.
  effect: CapsuleEffect,  // optional.
  on_detach: CapsuleOnDetach, // optional.
}

CapsuleTarget :: enum {
  SELF,
  OTHER,
}

Priority :: enum {
  HIGHEST,
  HIGHER,
  HIGH,
  NORMAL,
  LOW,
  LOWER,
  LOWEST,
}

CapsuleUse :: #type proc(source, target: ^Character) -> Response
CapsuleEffect :: #type proc(message: ^Response)
CapsuleOnDetach :: #type proc(target: ^Character)

// Action response
Response :: struct {
  source: ^Character,
  target: ^Character,
  initial_value: int,
  value: int,
  action: Action,
  flags: Flags,
}

Action :: enum {
  ATTACK,
  BUFF,
  DEFEND,
  HURT,
  NONE,
}

Flag :: enum {
  BLOCKED,
  CRITICAL,
  DEAD,
  DETACH, // capsule has to be detached
  DIRECT, // direct damage ignoring shields
  END, // not used yet
  GUARDBREAK, // ignore shield
  HEAL,
  MISS,
  NOCAPSULE,
  NODAMAGE,
  NOPAIN,
  IGNORE,
  OVERKILL,
  PARTIALBLOCK,
  PROTECT,
}

Flags :: distinct bit_set[Flag]

// A character
Character :: struct {
  name: string,
  level: int,
  health: int,
  pain: int,
  pain_rate: int,
  shield: int,
  max_health: int,
  healing: int,
  critical_rate: int,
  strength: int,
  defense: int,
  agility: int,
  strength_mul: int,
  defense_mul: int,
  max_items: int,
  immunity: [dynamic]string,
  active_capsules: [dynamic]^Capsule, // NOTE: why not using a map?
  inventory: [dynamic]^Capsule,
}

new_character :: proc() -> (c: ^Character) {
  c = new(Character)
  using c
  level = 1
  health = 50
  pain = 0
  pain_rate = 0
  shield = 0
  max_health = 50
  healing = 10
  critical_rate = 10
  strength = 1
  strength_mul = 1
  defense = 1
  defense_mul = 1
  agility = 1
  max_items = 4

  return c
}

delete_character :: proc(character: ^Character) {
  for capsule in character.active_capsules {
    detach(character, capsule.name)
  }
  for capsule in character.inventory {
    free(capsule)
  }
  delete_dynamic_array(character.inventory)
  delete_dynamic_array(character.active_capsules)
  delete_dynamic_array(character.immunity)
  free(character)
}

register_use :: proc(capsule: ^Capsule, use: CapsuleUse) {
  capsule.use = use
}

register_effect :: proc(capsule: ^Capsule, effect: CapsuleEffect) {
  capsule.effect = effect
}

register_on_detach :: proc(capsule: ^Capsule, on_detach: CapsuleOnDetach) {
  capsule.on_detach = on_detach
}

register_capsule :: proc(owner: ^Character, capsule: ^Capsule) -> bool {
  for c in owner.inventory {
    if c.name == capsule.name {
      return false
    }
  }

  if len(owner.inventory) > owner.max_items {
    return false
  }

  append_elem(&owner.inventory, capsule)
  return true
}

set_flag :: proc(flags: ^Flags, flag: Flag) {
  flags^ += {flag}
}

unset_flag :: proc(flags: ^Flags, flag: Flag) {
  flags^ -= {flag}
}

get_capsule_from_inventory :: proc(owner: ^Character, capsule_name: string) -> ^Capsule {
  /* 
    Get a capsule from owner's inventory
  */
  for capsule in owner.inventory {
    if capsule.name == capsule_name {
        return capsule
    }
  }
  return nil
}

get_active_capsule :: proc(target: ^Character, capsule_name: string) -> ^Capsule {
  for capsule in target.active_capsules{
    if capsule.name == capsule_name {
      return capsule
    }
  }
  return nil
}

activate :: proc(owner: ^Character, capsule_name: string) {
  for capsule in owner.inventory {
    if capsule.name == capsule_name {
      capsule.active = true
      break
    }
  }
}

deactivate :: proc(owner: ^Character, capsule_name: string) {
  for capsule in owner.inventory {
    if capsule.name == capsule_name {
      capsule.active = false
      break
    }
  }
}

attach :: proc(target: ^Character, capsule: ^Capsule) {
  append_elem(&target.active_capsules, capsule)

  if len(target.active_capsules) < 2 {
    return
  }

  index := len(target.active_capsules) - 1

  for {
    previous := index - 1
    if target.active_capsules[index].priority < target.active_capsules[previous].priority {
      swapped_capsule := target.active_capsules[index]
      target.active_capsules[index] = target.active_capsules[previous]
      target.active_capsules[previous] = swapped_capsule
    }
    index = previous
    if index == 0 {
      return
    }
  }
}

is_attached :: proc(target: ^Character, capsule_name: string) -> bool {
  for capsule in target.active_capsules {
    if capsule.name == capsule_name {
      return true
    }
  }

  return false
}

detach :: proc(target: ^Character, capsule_name: string)  {
  index := -1
  for capsule, i in target.active_capsules {
    if capsule.name == capsule_name {
      if capsule.on_detach != nil {
        capsule.on_detach(target)
      }
      index = i
      break
    }
  }
  if index > -1 {
    ordered_remove(&target.active_capsules, index)
  }
}

drop :: proc(owner: ^Character, capsule_name: string) {
  index := -1
  for capsule, i in owner.inventory {
    if capsule.name == capsule_name {
      index = i
      break
    }
  }
  if index > -1 {
    c := owner.inventory[index]
    ordered_remove(&owner.inventory, index)
    free(c)
  }
}

character_actions :: proc(owner: ^Character) -> (action_list: [dynamic]string) {
  for capsule in owner.inventory {
    if capsule.active {
      append_elem(&action_list, capsule.name)
    }
  }
  return action_list
}

hurt :: proc(message: ^Response) {
  using message

  if value == 0 {
    return
  }

  if .IGNORE in flags {
    unset_flag(&flags, .IGNORE)
    return
  }

  target.health -= value

  if target.health <= 0 {
    target.health = 0
    target.pain = 0
    target.pain_rate = 0
    set_flag(&flags, .DEAD)
    if value >= target.max_health {
      set_flag(&flags, .OVERKILL)
    }
  }

  if .NOPAIN not_in flags && target.health > 0 {
    target.pain += value
    target.pain_rate = target.pain * 100 / target.health
  }

  if target.pain_rate >= 100 {
    activate(message.target, "relieve")
  }
}

hurt_direct :: proc(target: ^Character, dmg: int, pain: bool = true) -> Flag {
  if dmg == 0 {
    return .NODAMAGE
  }

  target.health -= dmg

  if pain {
    target.pain += dmg
    target.pain_rate = target.pain * 100 / target.health
  }

  if target.health <= 0 {
    target.health = 0
    target.pain = 0
    target.pain_rate = 0
    return .DEAD
  }

  return .DIRECT
}

heal :: proc(target: ^Character, hp: int = -1) {
  if hp == -1 {
    health := target.max_health * target.healing / 100
    target.health += health
  } else {
    target.health += hp
  }
  if target.health > target.max_health {
    target.health = target.max_health
  }
}
