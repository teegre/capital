package scene

import rl "vendor:raylib"
import "../entities"
import "../room"

Scene :: struct {
  room: ^entities.Room,
  mode: Mode,
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

render_scene :: proc(scene: ^Scene) {
  origin: rl.Vector2
  room.draw_room(scene.room)
  for character in scene.characters {
    origin = {character.dest.width - character.size.w, character.dest.height - character.size.h}
    draw_shadow(character)
    rl.DrawTexturePro(character.texture, character.src, character.dest, origin, 0, rl.WHITE)
  }
}

draw_shadow :: proc(character: ^entities.Character) {
  color := rl.Color{0, 0, 0, 100}
  rl.DrawCircle(
    i32(character.dest.x + (character.size.w / 2) + 1),
    i32(character.dest.y + character.size.h - 1),
    character.size.h / 4, color)
}
