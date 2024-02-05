package actions

import "../entities"

perform_action :: proc(source, target: ^entities.Character, capsule_name: string) ->  (response: entities.Response) {
  using entities

  capsule := get_capsule_from_inventory(source, capsule_name)

  switch capsule.default_target {
  case .SELF:
    response = capsule.use(source, source)
  case .OTHER:
    response = capsule.use(source, target)
  }

  for response.action == .ATTACK && (.MISS not_in response.flags) {
    apply_passive_capsule_effects(&response, response.source)

    #partial switch response.action {
    case .ATTACK:
      response.action = .HURT
      fallthrough
    case .HURT:
      apply_passive_capsule_effects(&response, response.target)
      hurt(&response)
    // case .DEFEND:
    // case .NONE:
    }
  }

  return response
}

apply_passive_capsule_effects :: proc(message: ^entities.Response, character: ^entities.Character) {
  using entities

  to_detach: [dynamic]string
  defer delete_dynamic_array(to_detach)

  for capsule in character.active_capsules {
    if capsule.effect != nil {
      capsule.effect(message)
      if .DETACH in message.flags {
        unset_flag(&message.flags, .DETACH)
        append_elem(&to_detach, capsule.name)
      }
      if message.action == .NONE {
        break
      }
    }
  }
  for capsule_name in to_detach {
    detach(character, capsule_name)
  }
}
