package room

import rl "vendor:raylib"

draw_room :: proc(wall, floor, door: rl.Texture2D, screen_w, screen_h, w, h: int, tile_size: f32) {
  src, dest: rl.Rectangle
  origin: rl.Vector2

  src = {0, 0, tile_size, tile_size}
  dest = {0, 0, tile_size, tile_size}

  offset_x := (f32(screen_w) - (f32(w) * tile_size)) / 2
  offset_y := (f32(screen_h) - (f32(h) * tile_size)) / 2

  for i in 0..<(w*h) {
    src.x = 0
    src.y = 0
    dest.x = dest.width * f32(i % w) + offset_x
    dest.y = dest.height * f32(i / w) + offset_y
    origin = {dest.width, dest.height}

    if i == (w * h) - (w / 2) - 1 {
    // Door
      rl.DrawTexturePro(door, src, dest, origin, 0, rl.WHITE)
    } else if i % w == 0 || i / w == 0 || i % w == w - 1 || i / w == h - 1 {
    // Wall
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
