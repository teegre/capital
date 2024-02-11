package room

import rl "vendor:raylib"

// Automatic room generator:
// wall_tile, floor_tile, door_tile: rl.Texture2D
// position, size: rl.Vector2
// tile_size: int

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
    rl.DrawTexturePro(wall, src, dest, origin, 0, rl.WHITE)
  }
}
