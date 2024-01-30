package capsules

import "../entities"
import "attack"
import "shield"
import "relieve"
import "leech"
import "poison"

capsules_map := map[string]Entry{
  "attack" = attack.new_capsule,
  "shield" = shield.new_capsule,
  "relieve" = relieve.new_capsule,
  "leech" = leech.new_capsule,
  "poison" = poison.new_capsule,
}

capsule_list := []string{
  "autoshield",
  "berserk",
  "charity",
  "deflector",
  "embrace",
  "empathy",
  "endure",
  "escape",
  "fury",
  "leech",
  "morphine",
  "painkiller",
  "paralysis",
  "pass",
  "pinch",
  "poison",
  "prudence",
  "sacrifice",
  "shell",
  "steroids",
  "timebomb",
  "wall",
  "wreckage",
}

Entry :: #type proc(owner: ^entities.Character) -> bool

new_capsule :: proc(owner: ^entities.Character, capsule_name: string) -> bool {
  entry := capsules_map[capsule_name] or_else nil
  assert(type_of(entry) == Entry)
  return entry(owner)
}


