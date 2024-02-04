package main

import rl "vendor:raylib"

main :: proc() {
  using rl

  WIDTH :: 1920/2
  HEIGHT :: 1080/2

  InitWindow(WIDTH, HEIGHT, "THE VIDEO GAME!")
  SetTargetFPS(60)

  for !WindowShouldClose() {
    BeginDrawing()
      ClearBackground(rl.WHITE)
      DrawText("CAPITAL", 190, 200, 20, rl.LIGHTGRAY)
    EndDrawing()
  }

  CloseWindow()
}
