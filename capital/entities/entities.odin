package entities

import "core:fmt"
import "core:mem"
import "core:reflect"
import rl "vendor:raylib"

// A capsule
Capsule :: struct {
  name: string,
  description: string,
  texture: rl.Texture2D,
  src, dest: rl.Rectangle,
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

// A character
Statistics :: struct {
  level: int,
  health: int,
  pain: int,
  pain_mul: int,
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

Character :: struct {
  name: string,
  texture: rl.Texture2D,
  src: rl.Rectangle,
  dest: rl.Rectangle,
  direction: Direction,
  speed: f32,
  frame: int,
  max_frame: int,
  moving: bool,

  variant: union {
    ^Player,
    ^Enemy,
    ^Boss,
    ^NonPlayer,
  }
}

// The player
Player :: struct {
  using character: Character,
  using stats: Statistics,
}

Enemy :: struct {
  using character: Character,
  using stats: Statistics,
}

Boss :: struct {
  using character: Character,
  using stats: Statistics,
}

NonPlayer :: struct {
  using character: Character,
}

Direction :: enum {
  DOWN = 0,
  UP = 2,
  RIGHT = 4,
  LEFT = 6,
}

// A room
Room :: struct {
  // Spritesheet consists of 3 rows of 8 sprites and 1 row of 1 sprite:
  // Line 1: Walls (LC TE RC LE RE BL BE BR ).
  // Line 2: Entrance + animation.
  // Line 3: Exit door + animation
  // Line 4: Floor
  texture: rl.Texture2D,
  tile_size: u8,
  room: rl.Rectangle, // full room.
  area: rl.Rectangle, // living area.
  corridor: rl.Rectangle, // corridor connected to room.
  entrance: rl.Rectangle,
  exit: rl.Rectangle,
  entrance_opening: bool,
  entrance_closing: bool,
  entrance_frame: int,
  door_max_frame: int,
  exit_opening: bool,
  exit_closing: bool,
  exit_frame: int,
  entrance_opened: bool,
  entrance_locked: bool,
  exit_locked: bool,
  exit_opened: bool,
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
  action: Action,
  target: ^Character,
  initial_value: int,
  value: int,
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
  GUARDBREAK, // nullify shield
  HEAL,
  MISS,
  NOCAPSULE, // ??? is it relevant?
  NODAMAGE,
  NOPAIN,
  NUMB, // character cannot move
  IGNORE,
  OVERKILL,
  PARTIALBLOCK,
  PROTECT,
}

Flags :: distinct bit_set[Flag]

// TODO: COMBAT GROUP (Player(s) + Enemy(ies).


@(private)
new_character :: proc($T: typeid) -> ^Character {
  c := new(T)
  c.variant = c
  return c
}

new_player :: proc(name: string , texture_path: cstring) -> ^Character {
  c := new_character(Player)
  c.name = name
  c.texture = rl.LoadTexture(texture_path)

  p := c.variant.(^Player)
  p.level = 1
  p.health = 50
  p.pain = 0
  p.pain_rate = 0
  p.pain_mul = 1
  p.shield = 0
  p.max_health = 50
  p.healing = 10
  p.critical_rate = 10
  p.strength = 1
  p.strength_mul = 1
  p.defense = 1
  p.defense_mul = 1
  p.agility = 2
  p.max_items = 4
  p.speed = 1

  return c
}

new_enemy :: proc(name: string, texture_path: cstring) -> ^Character {
  c := new_character(Enemy)
  c.name = name
  c.texture = rl.LoadTexture(texture_path)

  e := c.variant.(^Enemy)
  e.level = 1
  e.health = 50
  e.pain = 0
  e.pain_rate = 0
  e.pain_mul = 1
  e.shield = 0
  e.max_health = 50
  e.healing = 10
  e.critical_rate = 10
  e.strength = 1
  e.strength_mul = 1
  e.defense = 1
  e.defense_mul = 1
  e.agility = 1
  e.max_items = 4

  return c
}

delete_character :: proc(character: ^Character) {
  fmt.println(character.name)
  stats := get_statistics(character)
  rl.UnloadTexture(character.texture)
  if stats != nil {
    fmt.println("Detaching active capsules...")
    for capsule in stats.active_capsules {
      detach(character, capsule.name)
    }
    fmt.println("Deleting capsules...")
    for capsule in stats.inventory {
      free(capsule)
    }
    delete_dynamic_array(stats.inventory)
    delete_dynamic_array(stats.active_capsules)
    delete_dynamic_array(stats.immunity)
  }
  free(character)
}

delete_room :: proc(room: ^Room) {
  rl.UnloadTexture(room.texture)
  free(room)
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
  stats := get_statistics(owner)
  for c in stats.inventory {
    if c.name == capsule.name {
      return false
    }
  }

  if len(stats.inventory) > stats.max_items {
    return false
  }

  append_elem(&stats.inventory, capsule)
  return true
}

set_flag :: proc(flags: ^Flags, flag: Flag) {
  flags^ += {flag}
}

unset_flag :: proc(flags: ^Flags, flag: Flag) {
  flags^ -= {flag}
}

// get Statistics struct of a Character
get_statistics :: proc(character: ^Character) -> ^Statistics {
  switch t in character.variant {
  case ^Player:
    return &t.variant.(^Player).stats
  case ^Enemy:
    return &t.variant.(^Enemy).stats
  case ^Boss:
    return &t.variant.(^Boss).stats
  case ^NonPlayer:
    return nil
  case:
    return nil
  }
  return nil
}

get_capsule_from_inventory :: proc(owner: ^Character, capsule_name: string) -> ^Capsule {
  stats := get_statistics(owner)

  for capsule in stats.inventory {
    if capsule.name == capsule_name {
        return capsule
    }
  }
  return nil
}

get_active_capsule :: proc(target: ^Character, capsule_name: string) -> ^Capsule {
  stats := get_statistics(target)
  for capsule in stats.active_capsules{
    if capsule.name == capsule_name {
      return capsule
    }
  }
  return nil
}

activate :: proc(owner: ^Character, capsule_name: string) {
  stats := get_statistics(owner)
  for capsule in stats.inventory {
    if capsule.name == capsule_name {
      capsule.active = true
      break
    }
  }
}

deactivate :: proc(owner: ^Character, capsule_name: string) {
  stats := get_statistics(owner)
  for capsule in stats.inventory {
    if capsule.name == capsule_name {
      capsule.active = false
      break
    }
  }
}

attach :: proc(target: ^Character, capsule: ^Capsule) {
  stats := get_statistics(target)
  append_elem(&stats.active_capsules, capsule)

  if len(stats.active_capsules) < 2 {
    return
  }

  index := len(stats.active_capsules) - 1

  for {
    previous := index - 1
    if stats.active_capsules[index].priority < stats.active_capsules[previous].priority {
      swapped_capsule := stats.active_capsules[index]
      stats.active_capsules[index] = stats.active_capsules[previous]
      stats.active_capsules[previous] = swapped_capsule
    }
    index = previous
    if index == 0 {
      return
    }
  }
}

is_attached :: proc(target: ^Character, capsule_name: string) -> bool {
  stats := get_statistics(target)
  for capsule in stats.active_capsules {
    if capsule.name == capsule_name {
      return true
    }
  }
  return false
}

detach :: proc(target: ^Character, capsule_name: string)  {
  stats := get_statistics(target)
  index := -1
  for capsule, i in stats.active_capsules {
    if capsule.name == capsule_name {
      if capsule.on_detach != nil {
        capsule.on_detach(target)
      }
      index = i
      break
    }
  }
  if index > -1 {
    ordered_remove(&stats.active_capsules, index)
  }
}

drop :: proc(owner: ^Character, capsule_name: string) {
  stats := get_statistics(owner)
  index := -1
  for capsule, i in stats.inventory {
    if capsule.name == capsule_name {
      index = i
      break
    }
  }
  if index > -1 {
    c := stats.inventory[index]
    ordered_remove(&stats.inventory, index)
    free(c)
  }
}

character_actions :: proc(owner: ^Character) -> (action_list: [dynamic]string) {
  stats := get_statistics(owner)
  for capsule in stats.inventory {
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

  stats := get_statistics(target)

  stats.health -= value

  if stats.health <= 0 {
    stats.health = 0
    stats.pain = 0
    stats.pain_rate = 0
    set_flag(&flags, .DEAD)
    if value >= stats.max_health {
      set_flag(&flags, .OVERKILL)
    }
  }

  if .NOPAIN not_in flags && stats.health > 0 {
    stats.pain += value * stats.pain_mul
    stats.pain_rate = stats.pain * 100 / stats.health
  }

  if stats.pain_rate >= 100 {
    activate(message.target, "relieve")
  }
}

hurt_direct :: proc(target: ^Character, dmg: int, pain: bool = true) -> Flag {
  if dmg == 0 {
    return .NODAMAGE
  }

  stats := get_statistics(target)

  stats.health -= dmg

  if pain {
    stats.pain += dmg * stats.pain_mul
    stats.pain_rate = stats.pain * 100 / stats.health
  }

  if stats.health <= 0 {
    stats.health = 0
    stats.pain = 0
    stats.pain_rate = 0
    return .DEAD
  }

  return .DIRECT
}

heal :: proc(target: ^Character, hp: int = -1) {
  stats := get_statistics(target)
  if hp == -1 {
    health := stats.max_health * stats.healing / 100
    stats.health += health
  } else {
    stats.health += hp
  }
  if stats.health > stats.max_health {
    stats.health = stats.max_health
  }
}
