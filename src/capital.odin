package main

import rl "vendor:raylib"
// import "core:log"
import "entities"
import "room"

running := true
player: ^entities.Player
player_indoor := true
player_next_to_entrance := false
player_next_to_exit := false

cam_zoom: bool = false
cam_zoom_target: f32 = 0.0
cam_zoom_increment: f32 = 0.0

tree, wall, floor, door: rl.Texture2D
main_room: ^entities.Room

r1, r2, r3, r4 : rl.Rectangle

camera: rl.Camera2D

TILE_SIZE :: 16

frame_count: int = 0

WIDTH :: 960
HEIGHT :: 560

init :: proc() {

  rl.InitWindow(WIDTH, HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))

  player = entities.new_player("virginie", "resources/virginie.png")
  main_room = room.make_room("resources/room-a.png", WIDTH, HEIGHT, 7, 7, TILE_SIZE)

  // context.logger = log.create_console_logger()
  // log.debugf("ROOM: %v", main_room)

  player.src = {0, 0, TILE_SIZE, TILE_SIZE,}
  player.dest = {(WIDTH/2)-(TILE_SIZE/2), main_room.corridor.height + main_room.corridor.y - TILE_SIZE, TILE_SIZE, TILE_SIZE}
  player.direction = 2

  camera.offset = rl.Vector2{WIDTH/2, HEIGHT/2}
  camera.zoom = 2.0
  camera.target = rl.Vector2{
    main_room.corridor.x + (main_room.corridor.width / 2),
    main_room.corridor.y + (main_room.corridor.height / 2),
  }
  // manage_camera()
}

update :: proc() {
  player.src.y = player.src.height * f32(player.direction)

  if player_next_to_entrance && !main_room.entrance_locked && !main_room.entrance_opening && !main_room.entrance_opened  && ((player.direction == 0 && player_indoor) || (player.direction == 2 && !player_indoor)) {
    player.moving = false
    main_room.entrance_opening = true
  } else if !player_next_to_entrance && main_room.entrance_opened && !main_room.entrance_closing {
    main_room.entrance_closing = true
  }

  if player_next_to_exit && !main_room.exit_locked && !main_room.exit_opening && !main_room.exit_opened  && ((player.direction == 2 && player_indoor) || (player.direction == 0 && !player_indoor)) {
    player.moving = false
    main_room.exit_opening = true
  } else if !player_next_to_exit && main_room.exit_opened && !main_room.exit_closing {
    main_room.exit_closing = true
  }

  if player.moving  && !main_room.entrance_opening && !main_room.exit_opening {
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

    manage_camera()

    if !player_indoor && !player_next_to_entrance && !player_next_to_exit {

      if player.dest.x < main_room.corridor.x {
        player.dest.x = main_room.corridor.x
      }
      if player.dest.x > main_room.corridor.x + main_room.corridor.width - player.dest.width {
        player.dest.x = main_room.corridor.x + main_room.corridor.width - player.dest.width
      }
      if player.dest.y < main_room.corridor.y {
        player.dest.y = main_room.corridor.y
      }
      if player.dest.y > main_room.corridor.y + main_room.corridor.height - player.dest.height {
        player.dest.y = main_room.corridor.y + main_room.corridor.height - player.dest.height
      }
    }

    if player_indoor && !player_next_to_entrance && !player_next_to_exit {
      if player.dest.x < main_room.area.x {
        player.dest.x = main_room.area.x
      }
      if player.dest.x > main_room.area.x + main_room.area.width - player.dest.width {
        player.dest.x = main_room.area.x + main_room.area.width - player.dest.width
      }
      if player.dest.y < main_room.area.y {
        player.dest.y = main_room.area.y
      }
      if player.dest.y > main_room.area.y + main_room.area.height - player.dest.height {
        player.dest.y = main_room.area.y + main_room.area.height - player.dest.height
      }
    } else {
      if player.dest.x < player.dest.width / 2 {
        player.dest.x = player.dest.width / 2
      }
      if player.dest.x > WIDTH - (player.dest.width / 2) {
        player.dest.x = WIDTH - (player.dest.width / 2)
      }
      if player.dest.y < -player.dest.height / 2 {
        player.dest.y = -player.dest.height / 2
      }
      if player.dest.y > HEIGHT - (player.dest.height / 2){
        player.dest.y = HEIGHT - (player.dest.height / 2)
      }
    }
  }

  if frame_count % 6 == 1 {
    player.frame += 1
  }

  frame_count += 1

  if player.frame > 2 {
    player.frame = 0
  }

  player.src.x = player.src.width * f32(player.frame)
  if player.moving {
    player.src.y = player.src.height * f32(player.direction + 1)
  }

  player.moving = false

  running = !rl.WindowShouldClose()
  check_collision()
}

manage_camera :: proc() {

  if cam_zoom && frame_count % 2 == 0 {
    if player.direction == 0 {// DOWN
      if f16le(camera.zoom) > 2.0 {
        cam_zoom = true
        cam_zoom_increment = -0.025
        cam_zoom_target = 2.0
      }
    } else if player.direction == 2 {// UP
      if f16le(camera.zoom) < 3.0 {
        cam_zoom = true
        cam_zoom_increment = 0.01
        cam_zoom_target = 3.0
      }
    }
    camera.zoom += cam_zoom_increment
  }

  if f16le(camera.zoom) == f16le(cam_zoom_target) {
    cam_zoom = false
    cam_zoom_increment = 0.0
    cam_zoom_target = 0.0
  }

  if player_indoor {
    camera.target = rl.Vector2{
      main_room.area.x + (main_room.area.width / 2),
      main_room.area.y + (main_room.area.height / 2),
    }
  } else if player.dest.y >= main_room.corridor.y + (main_room.corridor.height / 2) {
    camera.target = rl.Vector2{
      main_room.corridor.x + (main_room.corridor.width / 2),
      main_room.corridor.y + (main_room.corridor.height / 2),
    }
    if !cam_zoom && player.direction == 0 {// DOWN
      if f16le(camera.zoom) > 2.0 {
        cam_zoom = true
        cam_zoom_increment = -0.025
        cam_zoom_target = 2.0
      }
    } else if !cam_zoom && player.direction == 2 {// UP
      if f16le(camera.zoom) < 3.0 {
        cam_zoom = true
        cam_zoom_increment = 0.01
        cam_zoom_target = 3.0
      }
    }
  } else {
    camera.target = rl.Vector2{player.dest.x + (player.dest.width / 2), player.dest.y + (player.dest.height / 2)}
  }
}

check_collision :: proc() {
  r1 = rl.GetCollisionRec(player.dest, main_room.room)
  r2 = rl.GetCollisionRec(player.dest, main_room.area)
  r3 = rl.GetCollisionRec(player.dest, main_room.entrance)
  r4 = rl.GetCollisionRec(player.dest, main_room.exit)
  player_indoor = rl.CheckCollisionRecs(player.dest, main_room.area)
  player_next_to_entrance = (r3.width > TILE_SIZE - 4) && !main_room.entrance_locked
  player_next_to_exit = (r4.width > TILE_SIZE - 4) && !main_room.exit_locked
}

render :: proc() {
  rl.BeginDrawing()
    rl.ClearBackground(rl.Color{40, 40, 40, 255})
    rl.BeginMode2D(camera)
      draw()
    rl.EndMode2D()
  rl.EndDrawing()
}

draw :: proc() {
  rl.DrawRectangleLines(0, 0, WIDTH, HEIGHT, rl.RED)
  room.draw_room(main_room)
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
  // rl.DrawRectangleLines(
  //   i32(main_room.exit.x),
  //   i32(main_room.exit.y),
  //   i32(main_room.exit.width),
  //   i32(main_room.exit.height),
  //   rl.GREEN)
  // rl.DrawRectangleLines(
  //   i32(main_room.corridor.x),
  //   i32(main_room.corridor.y),
  //   i32(main_room.corridor.width),
  //   i32(main_room.corridor.height),
  //   rl.RED)

  // rl.DrawLine(WIDTH/2, 0, WIDTH/2, HEIGHT, rl.RED)
  // rl.DrawLine(0, HEIGHT/2, WIDTH, HEIGHT/2, rl.RED)

  // rl.DrawRectangle(i32(player.dest.x), i32(player.dest.y), i32(player.dest.width), i32(player.dest.height), rl.WHITE) // PLAYER
  // rl.DrawRectangle(i32(r1.x), i32(r1.y), i32(r1.width), i32(r1.height), rl.RED) // OUTSIDE WALLS
  // rl.DrawRectangle(i32(r2.x), i32(r2.y), i32(r2.width), i32(r2.height), rl.YELLOW) // LIVING AREA
  // rl.DrawRectangle(i32(r3.x), i32(r3.y), i32(r3.width), i32(r3.height), rl.GREEN) // DOOR

  // rl.DrawText(
  //   rl.TextFormat("area: %d,%d", i32(main_room.area.x), i32(main_room.area.y)),
  //   i32(main_room.area.x), i32(main_room.area.y), 2, rl.WHITE)
  // rl.DrawText(
  //   rl.TextFormat("%d,%d", i32(player.dest.x), i32(player.dest.y)),
  //   i32(player.dest.x), i32(player.dest.y - 10), 1, rl.WHITE)
  // rl.DrawText(
  //   rl.TextFormat("x%f->%f [%d]", f32(camera.zoom), f32(cam_zoom_target), int(cam_zoom)),
  //   i32(player.dest.x), i32(player.dest.y - 10), 1, rl.WHITE)


  origin: rl.Vector2 = {player.dest.width - TILE_SIZE, player.dest.height - TILE_SIZE}
  rl.DrawTexturePro(player.texture, player.src, player.dest, origin, 0, rl.WHITE)
}

input :: proc() {
  using rl.KeyboardKey
    if rl.IsKeyDown(UP) || rl.IsKeyDown(K) {
      player.moving = true
      player.direction = 2
    } else if rl.IsKeyDown(DOWN) || rl.IsKeyDown(J) {
      player.moving = true
      player.direction = 0
    } else if rl.IsKeyDown(LEFT) || rl.IsKeyDown(H) {
      player.moving = true
      player.direction = 6
    } else if rl.IsKeyDown(RIGHT) || rl.IsKeyDown(L) {
      player.moving = true
      player.direction = 4
    } else if rl.IsKeyPressed(SPACE) {
      main_room.entrance_locked = !main_room.entrance_locked
      main_room.exit_locked = !main_room.exit_locked
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
