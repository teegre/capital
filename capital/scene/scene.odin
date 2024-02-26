package scene

import rl "vendor:raylib"
import "../entities"
import "../room"

SCREEN_SCALING :: 160

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

render_scene :: proc(scene: ^Scene) {
  origin: rl.Vector2
  layer: u8 = 0

  room.draw_room(scene.room)
  for layer < 3 {
    for character in scene.characters {
      if character.layer == layer {
        draw_shadow(character)
        origin = {character.dest.width - character.size.w, character.dest.height - character.size.h}
        rl.DrawTexturePro(character.texture, character.src, character.dest, origin, 0, rl.WHITE)
      }
    }
    layer += 1
  }
}

draw_shadow :: proc(character: ^entities.Character) {
  color := rl.Color{0, 0, 0, 100}
  rl.DrawCircle(
    i32(character.dest.x + (character.size.w / 2) + 1),
    i32(character.dest.y + character.size.h - 1),
    character.size.h / 4, color)
}

// Calculate character layer according to player's position.
update_character_layers :: proc(scene: ^Scene, player: ^entities.Character) {
  for character in scene.characters {
    enemy, ok := character.variant.(^entities.Enemy)
    if ok {
      if character.dest.y + (character.dest.height / 2) < player.dest.y + (player.dest.height / 2) {
        character.layer = player.layer - 1
      } else {
        character.layer = player.layer + 1
      }
    }
  }
}
