package main

import rl "vendor:raylib"
import "core:log"
import "entities"
import "room"
import "scene"
import "capsules"

running := true
player: ^entities.Character
enemy: ^entities.Character
player_indoor := true
player_next_to_entrance := false
player_next_to_exit := false
player_step: int = 1

main_room: ^entities.Room

main_scene: ^scene.Scene

r1, r2, r3, r4 : rl.Rectangle

camera: rl.Camera2D

TILE_SIZE :: 16
SCREEN_SCALING :: 160

frame_count: int = 0

WIDTH :: 960
HEIGHT :: 560

zoom: f32

init :: proc() {

  rl.InitWindow(WIDTH, HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))

  player = entities.new_player("virginie", "capital/resources/virginie2.png")

  capsules.add_capsule_to_inventory(player, "attack")
  capsules.add_capsule_to_inventory(player, "shield")
  capsules.add_capsule_to_inventory(player, "relieve")

  player.max_frame = 3
  player.size = entities.Size{15, 23}

  enemy = entities.new_enemy("square", "capital/resources/enemy.png")

  capsules.add_capsule_to_inventory(enemy, "attack")
  capsules.add_capsule_to_inventory(enemy, "shield")
  capsules.add_capsule_to_inventory(enemy, "relieve")

  enemy.max_frame = 2
  enemy.size = entities.Size{16, 16}

  main_room = room.make_room("capital/resources/room-a.png", WIDTH, HEIGHT, 7, 7, TILE_SIZE)

  main_scene = new(scene.Scene)
  scene.add_to_scene(main_scene, main_room)
  scene.add_to_scene(main_scene, player)
  scene.add_to_scene(main_scene, enemy)

  // context.logger = log.create_console_logger()
  // log.debugf("SCENE: %v", main_scene)

  player.src = {0, 0, player.size.w, player.size.h}
  player.dest = {(WIDTH/2)-(TILE_SIZE/2), main_room.corridor.height + main_room.corridor.y - player.size.h , player.size.w, player.size.h}
  player.direction = .UP

  enemy.src = {0, 0, TILE_SIZE, TILE_SIZE}
  enemy.dest = {(WIDTH/2)-(TILE_SIZE/2), main_room.area.y, TILE_SIZE, TILE_SIZE}

  camera.offset = rl.Vector2{f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)}
  camera.target = rl.Vector2{f32(rl.GetScreenWidth()/2), player.dest.y}
  camera.zoom = f32(rl.GetScreenHeight() / SCREEN_SCALING)
}

update :: proc() {
  camera.offset = rl.Vector2{f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)}
  camera.zoom = f32(rl.GetScreenHeight() / SCREEN_SCALING) + zoom
  player.src.y = player.src.height * f32(player.direction)
  enemy.src.y = enemy.src.height * f32(enemy.direction)

  if player_next_to_entrance && !main_room.entrance_locked && !main_room.entrance_opening && !main_room.entrance_opened  && ((player.direction == .DOWN && player_indoor) || (player.direction == .UP && !player_indoor)) {
    player.moving = false
    main_room.entrance_opening = true
  } else if !player_next_to_entrance && main_room.entrance_opened && !main_room.entrance_closing {
    main_room.entrance_closing = true
  }

  if player_next_to_exit && !main_room.exit_locked && !main_room.exit_opening && !main_room.exit_opened  && ((player.direction == .UP && player_indoor) || (player.direction == .DOWN && !player_indoor)) {
    player.moving = false
    main_room.exit_opening = true
  } else if !player_next_to_exit && main_room.exit_opened && !main_room.exit_closing {
    main_room.exit_closing = true
  }

  if player.moving  && !main_room.entrance_opening && !main_room.exit_opening {
    switch player.direction {
    case .UP:
      player.dest.y -= player.speed
    case .RIGHT:
      player.dest.x += player.speed
    case .LEFT: // LEFT
      player.dest.x -= player.speed
    case .DOWN: // DOWN
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
      if player.dest.y < main_room.area.y - TILE_SIZE {
        player.dest.y = main_room.area.y - TILE_SIZE
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
      if player.dest.y > HEIGHT - player.size.h {
        player.dest.y = HEIGHT - player.size.h
      }
    }
  }

  if frame_count % 6 == 0 {
    enemy.frame += 1
    player.frame += player_step
  }

  frame_count += 1

  if player.frame > player.max_frame  - 1 {
    player.frame = player.max_frame - 1
    player_step = -1
  }

  if player.frame < 0 {
    player.frame = 0
    player_step = 1
  }

  if enemy.frame > enemy.max_frame {
    enemy.frame = 0
  }

  player.src.x = player.src.width * f32(player.frame)
  enemy.src.x = enemy.src.width * f32(enemy.frame)
  if player.moving {
    player.src.y = player.src.height * (f32(player.direction) + 1)
  }

  player.moving = false

  running = !rl.WindowShouldClose()
  check_collision()
}

manage_camera :: proc() {
  if player_indoor {
    camera.target = rl.Vector2{
      WIDTH/2,
      main_room.area.y + (main_room.area.height / 2),
    }
  } else {
    camera.target = rl.Vector2{
      WIDTH/2,
      player.dest.y,
    }
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
  scene.render_scene(main_scene)
  // room.draw_room(main_room)
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

  // rl.DrawRectangleLines(i32(player.dest.x), i32(player.dest.y), i32(player.dest.width), i32(player.dest.height), rl.WHITE) // PLAYER
  // rl.DrawRectangle(i32(r1.x), i32(r1.y), i32(r1.width), i32(r1.height), rl.RED) // OUTSIDE WALLS
  // rl.DrawRectangle(i32(r2.x), i32(r2.y), i32(r2.width), i32(r2.height), rl.YELLOW) // LIVING AREA
  // rl.DrawRectangle(i32(r3.x), i32(r3.y), i32(r3.width), i32(r3.height), rl.GREEN) // DOOR

  // rl.DrawText(
  //   rl.TextFormat("area: %d,%d", i32(main_room.area.x), i32(main_room.area.y)),
  //   i32(main_room.area.x), i32(main_room.area.y), 2, rl.WHITE)
  // rl.DrawText(
      // rl.TextFormat("%d/%d", i32(player.frame), i32(player_step)),
    // i32(player.dest.x - 3), i32(player.dest.y - 10), 1, rl.WHITE)
}

input :: proc() {
  using rl.KeyboardKey
    if rl.IsKeyDown(UP) || rl.IsKeyDown(K) {
      player.moving = true
      player.direction = .UP
    } else if rl.IsKeyDown(DOWN) || rl.IsKeyDown(J) {
      player.moving = true
      player.direction = .DOWN
    } else if rl.IsKeyDown(LEFT) || rl.IsKeyDown(H) {
      player.moving = true
      player.direction = .LEFT
    } else if rl.IsKeyDown(RIGHT) || rl.IsKeyDown(L) {
      player.moving = true
      player.direction = .RIGHT
    } else if rl.IsKeyPressed(SPACE) {
      main_room.entrance_locked = !main_room.entrance_locked
      main_room.exit_locked = !main_room.exit_locked
    } else if rl.IsKeyPressed(W) {
      zoom += 0.1
    } else if rl.IsKeyPressed(Q) {
      zoom -= 0.1
    }
}

quit :: proc() {
  delete_dynamic_array(main_scene.characters)
  free(main_scene)
  entities.delete_character(player)
  entities.delete_character(enemy)
  entities.delete_room(main_room)
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
