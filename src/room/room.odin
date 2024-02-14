package room

import rl "vendor:raylib"
import "../entities"

make_room :: proc(screen_w, screen_h, w, h, tile_size: f32) -> ^entities.Room {
  using entities, rl
    width := w * tile_size
    height := h * tile_size

    x := (screen_w - width) / 2
    y := (screen_h - height) / 2

    room := new(Room)
    room.room = Rectangle{x, y, width, height}
    room.area = Rectangle{
      room.room.x + tile_size,
      room.room.y + tile_size,
      width - (tile_size * 2),
      height - (tile_size * 2),
    }
    room.entrance = Rectangle{
      room.room.x + (width / 2) - (tile_size / 2),
      room.room.y + height - (tile_size * 1.5),
      tile_size,
      tile_size * 2,
    }
    room.exit_locked = true
    room.entrance_locked = false

    return room
}

draw_room :: proc(wall, floor, door: rl.Texture2D, room:  ^entities.Room, tile_size: f32) {
  src, dest: rl.Rectangle
  origin: rl.Vector2

  src = {0, 0, tile_size, tile_size}
  dest = {0, 0, tile_size, tile_size}

  w := int(room.room.width / tile_size)
  h := int(room.room.height / tile_size)

  x := room.room.x + tile_size
  y := room.room.y + tile_size
  // offset_x := ((f32(screen_w) - (f32(w) * tile_size)) / 2) + tile_size
  // offset_y := ((f32(screen_h) - (f32(h) * tile_size)) / 2) + tile_size

  for i in 0..<(w*h) {
    src.x = 0
    src.y = 0
    dest.x = x + (dest.width * f32(i % w))
    dest.y = y + (dest.height * f32(i / w))
    origin = {dest.width, dest.height}

    if i == (w * h) - (w / 2) - 1 {
    // Door
      rl.DrawTexturePro(door, src, dest, origin, 0, rl.WHITE)
    } else if i % w == 0 || i / w == 0 || i % w == w - 1 || i / w == h - 1 {
    // Wall
    // Horizontal spritesheet: TL TE TR LE RE BL BE BR
      if i == 0 { // top-left corner
        src.x = 0
      } else if i / w == 0  && i < w - 1 { // top edge
        src.x = tile_size
      } else if i == w - 1 { // top-right corner
        src.x = 2 * tile_size
      } else if i % w == 0 { // left edge
        src.x = 3 * tile_size
      } else if i % w == w - 1 && i < w * (h - 1) { // right edge
        src.x = 4 * tile_size
      }
      if i == w * (h - 1) { // bottom-left corner
        src.x = 5 * tile_size
      } else if i / w == h - 1 { // bottom edge
        src.x = 6 * tile_size
      }
      if i == (w * h) - 1 { // bottom-right corner
        src.x = 7 * tile_size
      }
      // src.x = tile_size * f32(i % 8)
      rl.DrawTexturePro(wall, src, dest, origin, 0, rl.WHITE)
    } else {
    // Floor
      rl.DrawTexturePro(floor, src, dest, origin, 0, rl.WHITE)
    }
  }
}
