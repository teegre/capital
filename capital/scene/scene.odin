package scene

import rl "vendor:raylib"
import "../entities"
import "../room"

SCREEN_SCALING :: 160
TILE_SIZE :: 16
WIDTH :: 960
HEIGHT :: 560

Scene :: struct {
  room: ^entities.Room,
  mode: Mode,
  camera: rl.Camera2D,
  zoom: f32,
  characters: [dynamic]^entities.Character,
}

Mode :: enum {
  ROOM,
  COMBAT,
  ELEVATOR,
}

Entity :: union {
  ^entities.Room,
  ^entities.Character,
}

add_to_scene :: proc(scene: ^Scene, entity: Entity) -> bool {
  switch _ in entity {
  case ^entities.Room:
    scene.room = entity.(^entities.Room)
    return true
  case ^entities.Character:
    append_elem(&scene.characters, entity.(^entities.Character))
    return true
  }
  return false
}

get_player :: proc(scene: ^Scene) -> ^entities.Character {
  for character in scene.characters {
    player, ok := character.variant.(^entities.Player)
    if ok {
      return player
    }
  }
  return nil
}

update_camera :: proc(scene: ^Scene) {
  player := get_player(scene)
  scene.camera.offset = rl.Vector2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
  scene.camera.zoom = f32(rl.GetScreenHeight() / SCREEN_SCALING) + scene.zoom
  if is_indoor(scene, player) {
    scene.camera.target = {
      WIDTH / 2,
      // f32(rl.GetScreenWidth() / 2),
      scene.room.area.y + (scene.room.area.height / 2),
    }
  } else {
    scene.camera.target = {
      WIDTH / 2,
      // f32(rl.GetScreenWidth() / 2),
      player.dest.y,
    }
  }
}

update_scene :: proc(scene: ^Scene) {
  check_collisions(scene)
  update_camera(scene)
  update_character_layers(scene)
  player := get_player(scene)
  trigger_entrance_door(scene, player)
  trigger_exit_door(scene, player)
}

animate :: proc(scene: ^Scene) {
  for character in scene.characters {
    character.frame += character.frame_step
    if character.frame > character.max_frame - 1 {
      character.frame = character.frame - 1
      character.frame_step = -1
    }
    if character.frame < 0 {
      character.frame = 0
      character.frame_step = 1
    }
    character.src.x = character.src.width * f32(character.frame)
    if character.moving {
      character.src.y = character.src.height * (f32(character.direction) + 1)
    } else {
      character.src.y = character.src.height * f32(character.direction)
    }
    character.moving = false
  }
}

render_scene :: proc(scene: ^Scene) {
  origin: rl.Vector2
  room.draw_room(scene.room)

  for layer in 0..<3 {
    for character in scene.characters {
      if character.layer == u8(layer) {
        draw_shadow(character)
        origin = {character.dest.width - character.size.w, character.dest.height - character.size.h}
        rl.DrawTexturePro(character.texture, character.src, character.dest, origin, 0, rl.WHITE)
      }
    }
  }
}

draw_shadow :: proc(character: ^entities.Character) {
  color := rl.Color{0, 0, 0, 100}
  rl.DrawCircle(
    i32(character.dest.x + (character.size.w / 2) + 1),
    i32(character.dest.y + character.size.h - 1),
    character.size.h / 4, color)
}

// Calculate characters' layer according to player's position.
update_character_layers :: proc(scene: ^Scene) {
  player := get_player(scene)
  pty := player.dest.y
  pby := player.dest.y + player.dest.height
  pmy := player.dest.y + (player.dest.height / 2)
  player_indoor := is_indoor(scene, player)

  for character in scene.characters {
    if is_indoor(scene, character) != player_indoor {
      continue
    }
    _, ok := character.variant.(^entities.Player)
    if !ok {
      cby := character.dest.y + character.dest.height
      cmy := character.dest.y + (character.dest.height / 2)

      // FRONT
      if cmy < pty && cby < pmy {
        character.layer = player.layer - 1
      // SAME
      } else if cmy < pby {
        character.layer = player.layer
      // BEHIND
      } else {
        character.layer = player.layer + 1
      }
    }
  }
}

is_indoor :: proc(scene: ^Scene, character: ^entities.Character) -> bool {
  return rl.CheckCollisionRecs(character.dest, scene.room.area)
}

is_next_to_entrance :: proc(scene: ^Scene, character: ^entities.Character) -> bool {
  entrance_collision_rec := rl.GetCollisionRec(character.dest, scene.room.entrance)
  return entrance_collision_rec.width > TILE_SIZE - 4 && !scene.room.entrance_locked
}

is_next_to_exit :: proc(scene: ^Scene, character: ^entities.Character) -> bool {
  exit_collision_rec := rl.GetCollisionRec(character.dest, scene.room.exit)
  return exit_collision_rec.width > TILE_SIZE - 4 && !scene.room.exit_locked
}

trigger_entrance_door :: proc(scene: ^Scene, character: ^entities.Character) {
  next_to_entrance :=  is_next_to_entrance(scene, character)
  indoor := is_indoor(scene, character)
  // player indoor, next to entrance, facing down, door closed, not locked and not opening
  // player outdoor, next to entrance, facing up, door closed, not locked and not opening
  may_open := !scene.room.entrance_opened && ((indoor && character.direction == .DOWN) || (!indoor && character.direction == .UP))
  if next_to_entrance && may_open && !scene.room.entrance_opening {
    character.moving = false
    scene.room.entrance_opening = true
  // close the door
  } else if !next_to_entrance && scene.room.entrance_opened && !scene.room.entrance_closing {
    scene.room.entrance_closing = true
  }
}

trigger_exit_door :: proc(scene: ^Scene, character: ^entities.Character) {
  next_to_exit := is_next_to_exit(scene, character)
  indoor := is_indoor(scene, character)
  // player indoor, next to exit, facing up, door closed, not locked and not opening
  // player outdoor, next to exit, facing down, door closed, not locked and not opening
  may_open := !scene.room.exit_opened && ((indoor && character.direction == .UP) || (!indoor && character.direction == .DOWN))
  if next_to_exit && may_open && !scene.room.exit_opening {
    character.moving = false
    scene.room.exit_opening = true
  // close the door
  } else if !next_to_exit && scene.room.exit_opened && !scene.room.exit_closing {
    scene.room.exit_closing = true
  }
}

check_collisions :: proc(scene: ^Scene) {
  player := get_player(scene)
  collision_rec: rl.Rectangle
  player_indoor := is_indoor(scene, player)

  for character in scene.characters {
      // ignore if player and character are not in the same place
      if is_indoor(scene, character) != player_indoor {
        continue
      }
    // with other characters
    _, ok := character.variant.(^entities.Player)
    if !ok {
      collision_rec = rl.GetCollisionRec(player.dest, character.dest)

      vert_x_overlap := collision_rec.height >= character.dest.width / 2
      vert_y_overlap := collision_rec.width >= character.dest.width / 4 // tolerance
      hor_x_overlap := collision_rec.height >= character.dest.width / 4

      switch player.direction {
      case .UP:
        if vert_x_overlap && vert_y_overlap && character.layer == 0 {
          player.moving = false
        }
      case .DOWN:
        if vert_x_overlap && vert_y_overlap && character.layer == 2 {
          player.moving = false
        }
      case .LEFT:
        if hor_x_overlap && player.dest.x > character.dest.x && character.layer == 1{
          player.moving = false
        }
      case .RIGHT:
        if hor_x_overlap && player.dest.x < character.dest.x && character.layer == 1 {
          player.moving = false
        }
      }
    }
  }

  // with walls
  next_to_entrance := is_next_to_entrance(scene, player)
  next_to_exit := is_next_to_exit(scene, player)
  min_x, max_x, min_y, max_y: f32
  place: rl.Rectangle

  if player_indoor {
    place = scene.room.area
    min_x = place.x
    max_x = place.x + place.width - player.dest.width
  } else {
    place = scene.room.corridor
    min_x = place.x + TILE_SIZE
    max_x = place.x + place.width - player.dest.width - TILE_SIZE
  }

  min_y = place.y - (TILE_SIZE / 2)
  max_y = place.y + place.height - player.dest.height - (TILE_SIZE / 2)

  if !next_to_entrance && !next_to_exit {
    if player.dest.x < min_x {
      player.dest.x = min_x
    }
    if player.dest.x > max_x {
      player.dest.x = max_x
    }
    if player.dest.y < min_y {
      player.dest.y = min_y
    }
    if player.dest.y > max_y {
      player.dest.y = max_y
    }
  }
}
