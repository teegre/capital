package actions

import "../entities"

perform_action :: proc(source, target: ^entities.Character, action: string) ->  (data: int, flags: entities.CapsuleFlags) {
  using entities
  // TODO SOURCE → PASSIVE CAPSULE EFFECTS HERE
  capsule := get_capsule_from_inventory(source, action)
  if capsule == nil {
    set_flag(&flags, .NOCAPSULE)
    return 0, flags
  }
  initial: int
  initial, flags = capsule.use(source, target)
  if .ATTACK in flags && .MISS not_in flags {
    // TODO TARGET → PASSIVE CAPSULE EFFECTS HERE
    data, hurt_flags := hurt(source, target, initial)
    return data, flags + hurt_flags
  }
  return data, flags
}
