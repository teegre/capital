package scene

import rl "vendor:raylib"
import "../entities"
import "../room"

SCREEN_SCALING :: 160
TILE_SIZE :: 16

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

update_camera :: proc(scene: ^Scene) {
  scene.camera.offset = rl.Vector2{f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)}
  scene.camera.zoom = f32(rl.GetScreenHeight() / SCREEN_SCALING) + scene.zoom
}

update_scene :: proc(scene: ^Scene) {
  update_camera(scene)
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
update_character_layers :: proc(scene: ^Scene, player: ^entities.Character) {
  for character in scene.characters {
    _, ok := character.variant.(^entities.Player)
    if !ok {
      if character.dest.y + (character.dest.height / 2) < player.dest.y + (player.dest.height / 2) {
        character.layer = player.layer - 1
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
  dir := character.direction == .UP || character.direction == .DOWN
  return entrance_collision_rec.width > TILE_SIZE - 4 && !scene.room.entrance_locked && dir
}

is_next_to_exit :: proc(scene: ^Scene, character: ^entities.Character) -> bool {
  exit_collision_rec := rl.GetCollisionRec(character.dest, scene.room.exit)
  dir := character.direction == .UP || character.direction == .DOWN
  return exit_collision_rec.width > TILE_SIZE - 4 && !scene.room.exit_locked && dir
}

check_collisions :: proc(scene: ^Scene, player: ^entities.Character) {
  collision_rec: rl.Rectangle
  for character in scene.characters {
    _, ok := character.variant.(^entities.Player)
    if !ok {
      collision_rec = rl.GetCollisionRec(player.dest, character.dest)
      y_ok := collision_rec.width < TILE_SIZE / 4
      x_ok := collision_rec.height < player.dest.height - (TILE_SIZE / 4)
      switch player.direction {
      case .UP:
       if !y_ok && character.layer == 0 {
         player.dest.y = character.dest.y + character.dest.height - (TILE_SIZE / 4)
         player.moving = false
      }
      case .DOWN:
      if !y_ok && character.layer == 2 {
        player.dest.y = character.dest.y - (TILE_SIZE / 2)
        player.moving = false
      }
      case .LEFT:
      if !x_ok {
        player.dest.x = character.dest.x + character.dest.width
        player.moving = false
      }
      case .RIGHT:
      if !x_ok {
        player.dest.x = character.dest.x - player.dest.width
        player.moving = false
      }
      }
    }
  }
}
