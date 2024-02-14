package main

import rl "vendor:raylib"
import "entities"
import "room"

running := true
player: rl.Texture2D
tree, wall, floor, door: rl.Texture2D
main_room: ^entities.Room
player_src: rl.Rectangle
player_dest: rl.Rectangle
player_speed: f32 = 1
player_direction: int = 0
player_frame: int = 0
player_moving: bool = false

camera: rl.Camera2D

TILE_SIZE :: 16

frame_count: int = 0

WIDTH :: 960
HEIGHT :: 540

init :: proc() {

  rl.InitWindow(WIDTH, HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))

  player = rl.LoadTexture("resources/virginie.png")
  wall = rl.LoadTexture("resources/walls.png")
  floor = rl.LoadTexture("resources/floors.png")
  door = rl.LoadTexture("resources/doors.png")

  main_room = room.make_room(WIDTH, HEIGHT, 7, 7, TILE_SIZE)

  player_src = {0, 0, TILE_SIZE, TILE_SIZE,}
  player_dest = {WIDTH/2+8, HEIGHT/2+8, TILE_SIZE, TILE_SIZE}

  camera.offset = rl.Vector2{WIDTH/2, HEIGHT/2}
  camera.target = rl.Vector2{player_dest.x - (player_dest.width / 2), player_dest.y - (player_dest.height / 2)}
  camera.rotation = 0.0
  camera.zoom = 3.0
}

update :: proc() {
  player_src.y = player_src.width * f32(player_direction)

  if player_moving {
    switch player_direction {
    case 2:
      player_dest.y -= player_speed
    case 4:
      player_dest.x += player_speed
    case 6:
      player_dest.x -= player_speed
    case 0:
      player_dest.y += player_speed
    }

    if player_dest.x < player_dest.width + 4 {
      player_dest.x = player_dest.width + 4
    }
    if player_dest.x > WIDTH - 4 {
      player_dest.x = WIDTH - 4
    }
    if player_dest.y < player_dest.height - 4 {
      player_dest.y = player_dest.height - 4
    }
    if player_dest.y > HEIGHT - 4 {
      player_dest.y = HEIGHT - 4
    }

    player_src.y = player_src.width * f32(player_direction + 1)
  }

  if frame_count % 6 == 1 {
    player_frame += 1
  }

  frame_count += 1

  if player_frame > 2 {
    player_frame = 0
  }

  player_src.x = player_src.width * f32(player_frame)

  player_moving = false

  running = !rl.WindowShouldClose()
  camera.target = rl.Vector2{player_dest.x - (player_dest.width / 2), player_dest.y - (player_dest.height / 2)}
}

render :: proc() {
  rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
    rl.BeginMode2D(camera)
      draw()
    rl.EndMode2D()
  rl.EndDrawing()
}

draw :: proc() {
  rl.DrawRectangleLines(0, 0, WIDTH, HEIGHT, rl.RED)
  room.draw_room(wall, floor, door, main_room, TILE_SIZE)
  // DEBUG
  // rl.DrawCircle(WIDTH/2, HEIGHT/2, 8, rl.SKYBLUE)
  // rl.DrawRectangleLines(
  //   i32(main_room.room.x),
  //   i32(main_room.room.y),
  //   i32(main_room.room.width),
  //   i32(main_room.room.height),
  //   rl.RED)
  // rl.DrawRectangleLines(
  //   i32(main_room.entrance.x),
  //   i32(main_room.entrance.y),
  //   i32(main_room.entrance.width),
  //   i32(main_room.entrance.height),
  //   rl.GREEN)
  // rl.DrawRectangleLines(
  //   i32(main_room.area.x),
  //   i32(main_room.area.y),
  //   i32(main_room.area.width),
  //   i32(main_room.area.height),
  //   rl.YELLOW)
  origin: rl.Vector2 = {player_dest.width, player_dest.height}
  rl.DrawTexturePro(player, player_src, player_dest, origin, 0, rl.WHITE)
}

input :: proc() {
  using rl.KeyboardKey
    if rl.IsKeyDown(UP) || rl.IsKeyDown(K) {
      player_moving = true
      player_direction = 2
    }
    if rl.IsKeyDown(DOWN) || rl.IsKeyDown(J) {
      player_moving = true
      player_direction = 0
    }
    if rl.IsKeyDown(LEFT) || rl.IsKeyDown(H) {
      player_moving = true
      player_direction = 6
    }
    if rl.IsKeyDown(RIGHT) || rl.IsKeyDown(L) {
      player_moving = true
      player_direction = 4
    }
}

quit :: proc() {
  rl.UnloadTexture(player)
  free(main_room)
  rl.CloseWindow()
}

main :: proc() {
  init()

  for running {
    input()
    update()
    render()
  }

  quit()
}
