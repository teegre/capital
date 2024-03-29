package room

import rl "vendor:raylib"
import "../entities"

make_room :: proc(texture_path: cstring, screen_w, screen_h, w, h, tile_size: f32) -> ^entities.Room {
  using entities, rl

    width := w * tile_size
    height := h * tile_size

    x := (screen_w - width) / 2
    y := (screen_h - height) / 2

    room := new(Room)
    room.texture = LoadTexture(texture_path)
    room.tile_size = u8(tile_size)
    room.room = Rectangle{x, y, width, height}
    room.area = Rectangle{
      room.room.x + tile_size,
      room.room.y + tile_size,
      width - (tile_size * 2),
      height - (tile_size * 2),
    }
    room.corridor = Rectangle{
      room.room.x,
      room.room.y + room.room.height,
      room.room.width,
      screen_h - room.room.y - room.room.height,
    }
    room.entrance = Rectangle{
      room.room.x + (width / 2) - (tile_size / 2),
      room.room.y + height - (tile_size * 1.5),
      tile_size,
      tile_size * 2,
    }
    room.exit = Rectangle{
      room.room.x + (width / 2) - (tile_size / 2),
      room.room.y - tile_size / 2,
      tile_size,
      tile_size * 2,
    }

    room.door_max_frame = int(room.texture.width / i32(tile_size))
    room.exit_locked = false
    room.entrance_locked = false

    return room
}

draw_room :: proc(room: ^entities.Room) {
  src, dest: rl.Rectangle
  origin: rl.Vector2
  tile_size := f32(room.tile_size)

  src = {0, 0, tile_size, tile_size}
  dest = {0, 0, tile_size, tile_size}

  w := int(room.room.width / tile_size)
  h := int(room.room.height / tile_size)

  for i in 0..<(w*h) {
    src.x = 0
    src.y = 0
    dest.x = room.room.x + dest.width * f32(i % w)
    dest.y = room.room.y + dest.height * f32(i / w)
    origin = {dest.width - tile_size, dest.height - tile_size}

    if i == (w / 2) {
    // Exit door
      src.y = 2 * tile_size
      if room.exit_opening {
        if room.exit_frame == room.door_max_frame {
          room.exit_opening = false
          room.exit_opened = true
        } else {
          src.x = f32(room.exit_frame) * tile_size
          room.exit_frame += 1
        }
      }
      if room.exit_closing {
        if room.exit_frame == -1 {
          room.exit_frame = 0
          room.exit_closing = false
          room.exit_opened = false
        } else {
          src.x = f32(room.exit_frame) * tile_size
          room.exit_frame -= 1
        }
      }
      if room.exit_opened && !room.exit_closing {
        src.x = f32(room.door_max_frame - 1) * f32(tile_size)
      }
    } else if i == (w * h) - (w / 2) - 1 {
    // Entrance door
      src.y = tile_size
      if room.entrance_opening {
        if room.entrance_frame == room.door_max_frame {
          room.entrance_opening = false
          room.entrance_opened = true
        } else {
          src.x = f32(room.entrance_frame) * tile_size
          room.entrance_frame += 1
        }
      }
      if room.entrance_closing {
        if room.entrance_frame == -1 {
          room.entrance_frame = 0
          room.entrance_closing = false
          room.entrance_opened = false
        } else {
          src.x = f32(room.entrance_frame * int(tile_size))
          room.entrance_frame -= 1
        }
      }
      if room.entrance_opened && !room.entrance_closing {
        src.x = f32(room.door_max_frame - 1) * f32(tile_size)
      }
    } else if i % w == 0 || i / w == 0 || i % w == w - 1 || i / w == h - 1 {
    // Wall
      src.y = 0
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
    } else {
      // Floor
      src.x = tile_size
      src.y = 3 * tile_size
    }
    rl.DrawTexturePro(room.texture, src, dest, origin, 0, rl.WHITE)
  }
  draw_corridor(room)
}

draw_corridor :: proc(room: ^entities.Room) {
  tile_size := f32(room.tile_size)
  src, dest: rl.Rectangle
  origin: rl.Vector2

  w := int(room.corridor.width / tile_size)
  h := int(room.corridor.height / tile_size)
  src = {0, 3 * tile_size, tile_size, tile_size}
  dest = {0, 0, tile_size, tile_size}

  for i in 0..<(w*h) {
    if i % w == 0 { src.x = 0 }
    else if i % w == w - 1 { src.x = 2 * tile_size }
    else { src.x = tile_size }
    dest.x = room.corridor.x + dest.width * f32(i % w)
    dest.y = room.corridor.y + dest.height * f32(i / w)
    origin = {dest.width - tile_size, dest.height - tile_size}
    rl.DrawTexturePro(room.texture, src, dest, origin, 0, rl.WHITE)
  }
}
