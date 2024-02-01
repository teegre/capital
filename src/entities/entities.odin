package entities

import "core:fmt"

// A capsule
Capsule :: struct {
  name: string,
  description: string,
  active: bool, // if active, capsule can be listed as an action for the owner.
  owner: ^Character,
  default_target: CapsuleTarget, // default target may be self or other.
  value: int, // used internally to store data.
  use: CapsuleUse,
  effect: CapsuleEffect,
}

CapsuleUse :: #type proc(source, target: ^Character) -> Response
CapsuleEffect :: #type proc(message: ^Response)
// OnAttach :: #type proc()
// OnDetach :: #type proc()
// OnActivate :: #type proc()
// OnDeactivate :: #type proc()

Response :: struct {
  source: ^Character,
  target: ^Character,
  value: int,
  action: Action,
  flags: Flags,
}

Action :: enum {
  ATTACK,
  DEFEND,
  HEAL,
  HURT,
  NONE,
}

Flag :: enum {
  MISS,
  CRITICAL,
  DEAD,
  OVERKILL,
  NOCAPSULE,
  BLOCKED,
  PARTIALBLOCK,
  NODAMAGE,
  NOPAIN,
}

Flags :: distinct bit_set[Flag]

CapsuleTarget :: enum {
  SELF,
  OTHER,
}


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
  active_capsules: [dynamic]^Capsule,
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
  incl_elem(flags, flag)
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
  for capsule in target.active_capsules {
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
}

detach :: proc(target: ^Character, capsule_name: string) {
  index := -1
  for capsule, i in target.active_capsules {
    if capsule.name == capsule_name {
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
    fmt.println("dropped", c.name)
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

  if message.value == 0 {
    return
  }

  message.action = .HURT

  message.target.health -= message.value

  if message.target.health <= 0 {
    message.target.health = 0
    message.target.pain = 0
    message.target.pain_rate = 0
    set_flag(&message.flags, .DEAD)
    if message.value >= message.target.max_health {
      set_flag(&message.flags, .OVERKILL)
    }
  }

  if .NOPAIN not_in message.flags && message.target.health > 0 {
    using message.target
    pain += message.value
    pain_rate = pain * 100 / health
  }

  if message.target.pain_rate > 100 {
    activate(message.target, "relieve")
  }
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
