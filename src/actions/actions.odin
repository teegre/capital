package actions

import "../entities"

perform_action :: proc(source, target: ^entities.Character, capsule_name: string) ->  (response: entities.Response) {
  using entities

  capsule := get_capsule_from_inventory(source, capsule_name)
  if capsule == nil || capsule.active == false {
    return Response{
      source = source,
      target = target,
      value = 0,
      action = .NONE,
      flags = {.NOCAPSULE,},
    }
  }

  response = capsule.use(source, target)
  if .MISS in response.flags {
    return response
  }

  // SOURCE → PASSIVE CAPSULE EFFECTS HERE
  apply_passive_capsule_effects(&response, source)
  // TARGET → PASSIVE CAPSULE EFFECTS HERE
  apply_passive_capsule_effects(&response, target)

  if response.action == .ATTACK {
    hurt(&response)
    apply_passive_capsule_effects(&response, target)
  }

  return response
}

apply_passive_capsule_effects :: proc(message: ^entities.Response, character: ^entities.Character) {
  for capsule in character.active_capsules {
    if capsule.effect != nil {
      capsule.effect(message)
    }
  }
}
