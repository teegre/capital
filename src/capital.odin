package main

import rl "vendor:raylib"
import "entities"
import "room"

running := true
player: ^entities.Player
player_texture: rl.Texture2D
player_indoor := true
tree, wall, floor, door: rl.Texture2D
main_room: ^entities.Room

r1, r2, r3 : rl.Rectangle

camera: rl.Camera2D

TILE_SIZE :: 16

frame_count: int = 0

WIDTH :: 960
HEIGHT :: 540

init :: proc() {

  rl.InitWindow(WIDTH, HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))

  wall = rl.LoadTexture("resources/walls.png")
  floor = rl.LoadTexture("resources/floors.png")
  door = rl.LoadTexture("resources/doors.png")

  player = entities.new_player("virginie", "resources/virginie.png")

  main_room = room.make_room(WIDTH, HEIGHT, 7, 7, TILE_SIZE)

  player.src = {0, 0, TILE_SIZE, TILE_SIZE,}
  player.dest = {(WIDTH/2)-(TILE_SIZE/2), (HEIGHT/2)-(TILE_SIZE/2), TILE_SIZE, TILE_SIZE}

  camera.offset = rl.Vector2{WIDTH/2, HEIGHT/2}
  camera.target = rl.Vector2{player.dest.x - (player.dest.width / 2), player.dest.y - (player.dest.height / 2)}
  camera.rotation = 0.0
  camera.zoom = 3.0
}

update :: proc() {
  player.src.y = player.src.width * f32(player.direction)

  if player.moving {
    switch player.direction {
    case 2: // UP
      player.dest.y -= player.speed
    case 4: // RIGHT
      player.dest.x += player.speed
    case 6: // LEFT
      player.dest.x -= player.speed
    case 0: // DOWN
      player.dest.y += player.speed
    }

    if player.dest.x < player.dest.width + 4 {
      player.dest.x = player.dest.width + 4
    }
    if player.dest.x > WIDTH - 4 {
      player.dest.x = WIDTH - 4
    }
    if player.dest.y < player.dest.height - 4 {
      player.dest.y = player.dest.height - 4
    }
    if player.dest.y > HEIGHT - 4 {
      player.dest.y = HEIGHT - 4
    }

    player.src.y = player.src.width * f32(player.direction + 1)
  }

  if frame_count % 6 == 1 {
    player.frame += 1
  }

  frame_count += 1

  if player.frame > 2 {
    player.frame = 0
  }

  player.src.x = player.src.width * f32(player.frame)

  player.moving = false

  running = !rl.WindowShouldClose()
  camera.target = rl.Vector2{player.dest.x - (player.dest.width / 2), player.dest.y - (player.dest.height / 2)}
  check_collision()
}

check_collision :: proc() {
  r1 = rl.GetCollisionRec(player.dest, main_room.room)
  r2 = rl.GetCollisionRec(player.dest, main_room.area)
  if rl.CheckCollisionRecs(player.dest, main_room.area) {
    player_indoor = true
  } else {
    player_indoor = false
  }
  r3 = rl.GetCollisionRec(player.dest, main_room.entrance)
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
  rl.DrawCircle(WIDTH/2, HEIGHT/2, 8, rl.SKYBLUE)
  rl.DrawRectangleLines(
    i32(main_room.room.x),
    i32(main_room.room.y),
    i32(main_room.room.width),
    i32(main_room.room.height),
    rl.RED)
  rl.DrawRectangleLines(
    i32(main_room.entrance.x),
    i32(main_room.entrance.y),
    i32(main_room.entrance.width),
    i32(main_room.entrance.height),
    rl.GREEN)
  rl.DrawRectangleLines(
    i32(main_room.area.x),
    i32(main_room.area.y),
    i32(main_room.area.width),
    i32(main_room.area.height),
    rl.YELLOW)

  rl.DrawLine(WIDTH/2, 0, WIDTH/2, HEIGHT, rl.RED)
  rl.DrawLine(0, HEIGHT/2, WIDTH, HEIGHT/2, rl.RED)

  rl.DrawRectangleLines(i32(player.dest.x), i32(player.dest.y), i32(player.dest.width), i32(player.dest.height), rl.WHITE) // PLAYER
  rl.DrawRectangleLines(i32(r1.x), i32(r1.y), i32(r1.width), i32(r1.height), rl.BLUE) // OUTSIDE WALLS
  rl.DrawRectangleLines(i32(r2.x), i32(r2.y), i32(r2.width), i32(r2.height), rl.PURPLE) // LIVING AREA
  rl.DrawRectangleLines(i32(r3.x), i32(r3.y), i32(r3.width), i32(r3.height), rl.GREEN) // DOOR

  origin: rl.Vector2 = {player.dest.width - TILE_SIZE, player.dest.height - TILE_SIZE}
  rl.DrawTexturePro(player.texture, player.src, player.dest, origin, 0, rl.WHITE) 
  // rl.DrawText(rl.TextFormat("Center: %d,%d | Player: %f,%f", WIDTH/2, HEIGHT/2, player.dest.x, player.dest.y), WIDTH/2, HEIGHT/2, 8, rl.WHITE)
}

input :: proc() {
  using rl.KeyboardKey
    if rl.IsKeyDown(UP) || rl.IsKeyDown(K) {
      player.moving = true
      player.direction = 2
    }
    if rl.IsKeyDown(DOWN) || rl.IsKeyDown(J) {
      player.moving = true
      player.direction = 0
    }
    if rl.IsKeyDown(LEFT) || rl.IsKeyDown(H) {
      player.moving = true
      player.direction = 6
    }
    if rl.IsKeyDown(RIGHT) || rl.IsKeyDown(L) {
      player.moving = true
      player.direction = 4
    }
}

quit :: proc() {
  rl.UnloadTexture(player.texture)
  entities.delete_player(player)
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
