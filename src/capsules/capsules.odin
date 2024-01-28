package capsules

import "../entities"
import "attack"
import "shield"
import "relieve"

capsules_map := map[string]Entry{
  "attack" = attack.new_capsule,
  "shield" = shield.new_capsule,
  "relieve" = relieve.new_capsule,
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

Entry :: #type proc() -> ^entities.Capsule

get_new_capsule :: proc(name: string) -> ^entities.Capsule {
  entry := capsules_map[name] or_else nil
  assert(type_of(entry) == Entry)
  return entry()
}
