package main

import rl "vendor:raylib"

running := true
player: rl.Texture2D
tree: rl.Texture2D
player_src: rl.Rectangle
player_dest: rl.Rectangle
player_speed: f32 = 3
player_direction: int = 0
player_frame: int = 0
player_moving: bool = false
tree_src: rl.Rectangle
tree_dest: rl.Rectangle

camera: rl.Camera2D

frame_count: int = 0

WIDTH :: 1920/2
HEIGHT :: 1080/2



// input :: proc()
init :: proc() {
  rl.InitWindow(WIDTH, HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))
  player = rl.LoadTexture("resources/virginie.png")
  tree = rl.LoadTexture("resources/tree.png")
  player_src = {0, 0, 16, 16,}
  player_dest = {WIDTH/2, HEIGHT/2, 48, 48}
  tree_src = {0, 0, 16, 16}
  tree_dest = {WIDTH/2, HEIGHT/2, 48, 48}
  camera.offset = rl.Vector2{WIDTH/2, HEIGHT/2}
  camera.target = rl.Vector2{player_dest.x - (player_dest.width / 2), player_dest.y - (player_dest.height / 2)}
  camera.rotation = 0.0
  camera.zoom = 1.0
}

update :: proc() {
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

    if frame_count % 8 == 1 {
      player_frame += 1
    }
    
    player_src.y = player_src.width * f32(player_direction + 1)

  } else {
    player_src.y = player_src.width * f32(player_direction)

    if frame_count % 12 == 1 {
      player_frame += 1
    }
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
    rl.ClearBackground(rl.DARKGRAY)
    rl.BeginMode2D(camera)
      draw()
    rl.EndMode2D()
  rl.EndDrawing()
}

draw :: proc() {
  origin: rl.Vector2 = {tree_dest.width, tree_dest.height}
  rl.DrawTexturePro(tree, tree_src, tree_dest, origin, 0, rl.WHITE)
  origin = {player_dest.width, player_dest.height}
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
