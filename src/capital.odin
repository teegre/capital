package main

import rl "vendor:raylib"

main :: proc() {
  WIDTH :: 800
  HEIGHT :: 480

  rl.InitWindow(WIDTH, HEIGHT, "THE VIDEO GAME!")
  rl.SetTargetFPS(60)

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
      rl.ClearBackground(rl.WHITE)
      rl.DrawText("PAINKILLER", 190, 200, 20, rl.LIGHTGRAY)
    rl.EndDrawing()
  }

  rl.CloseWindow()
}
