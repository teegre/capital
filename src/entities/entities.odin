package entities

import "core:fmt"

CapsuleFlag :: enum {
  ATTACHED,
  BLOCKED,
  CRITICAL,
  DEAD,
  DODGE,
  ESCAPED,
  HEALED,
  IMMUNE,
  MISS,
  NOCAPSULE,
  NODAMAGE,
  NOEFFECT,
  NOPAIN,
  OVERKILL,
}

CapsuleEventName :: enum {
  ACTIVATE,
  ATTACH,
  ATTACK,
  DEACTIVATE,
  DEFEND,
  DETACH,
  HURT,
  PASS,
}


CapsuleFlags :: distinct bit_set[CapsuleFlag]
CapsuleUse :: #type proc(source, target: ^Character) -> (value: int, action: CapsuleEventName, flags: CapsuleFlags)
CapsuleEffect :: #type proc(source, target: ^Character, event_name: CapsuleEventName, data: int) -> (value: int, flags: CapsuleFlags)
// OnAttach :: #type proc()
// OnDetach :: #type proc()
// OnActivate :: #type proc()
// OnDeactivate :: #type proc()

// A capsule
Capsule :: struct {
  name: string,
  description: string,
  active: bool,
  owner: ^Character,
  target: ^Character,
  value: int,
  use: CapsuleUse,
  effect: CapsuleEffect,
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
  for capsule in character.inventory {
    free(capsule)
  }
  for capsule in character.active_capsules {
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

set_flag :: proc(flags: ^CapsuleFlags, flag: CapsuleFlag) {
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

hurt :: proc(source, target: ^Character, hit: int) -> (dmg: int, flags: CapsuleFlags) {
  initial_dmg := hit

  if target.shield == initial_dmg {
    target.shield = 0
    dmg = 0
    set_flag(&flags, .BLOCKED)
  } else if target.shield > initial_dmg {
    target.shield -= initial_dmg
    dmg = 0
  } else if target.shield > 0 {
    dmg = initial_dmg - target.shield
    target.shield -= initial_dmg
    if target.shield < 0 {
      target.shield = 0
    }
  } else {
    dmg = initial_dmg
  }

  target.health -= dmg

  if target.health <= 0 {
    target.health = 0
    set_flag(&flags, .DEAD)
    if dmg >= target.max_health {
      set_flag(&flags, .OVERKILL)
    }
    return dmg, flags
  }

  target.pain += dmg
  target.pain_rate = target.pain * 100 / target.health

  if target.pain_rate >= 100 {
    activate(target, "relieve")
  }

  return dmg, flags
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
