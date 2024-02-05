package capsules

import "../entities"
import "attack"
import "shield"
import "relieve"
import "leech"
import "poison"
import "wall"
import "berserk"
import "steroids"
import "deflector"
import "wreckage"
import "prudence"

capsules_map := map[string]Entry{
  "attack" = attack.new_capsule,
  "shield" = shield.new_capsule,
  "relieve" = relieve.new_capsule,
  "leech" = leech.new_capsule,
  "poison" = poison.new_capsule,
  "wall" = wall.new_capsule,
  "berserk" = berserk.new_capsule,
  "steroids" = steroids.new_capsule,
  "deflector" = deflector.new_capsule,
  "wreckage" = wreckage.new_capsule,
  "prudence" = prudence.new_capsule,
}

capsule_list := []string{
  "autoshield",
  "berserk", // OK
  "charity",
  "deflector", // OK
  "embrace",
  "empathy",
  "endure",
  "escape",
  "fury",
  "leech", // OK
  "morphine",
  "painkiller",
  "paralysis",
  "pass",
  "pinch",
  "poison", // OK
  "prudence", // OK
  "sacrifice",
  "shell",
  "steroids", // OK
  "timebomb",
  "wall", // OK
  "wreckage", // OK
}

Entry :: #type proc(owner: ^entities.Character) -> bool

add_capsule_to_inventory :: proc(owner: ^entities.Character, capsule_name: string) -> bool {
  entry := capsules_map[capsule_name] or_else nil
  assert(type_of(entry) == Entry)
  return entry(owner)
}
