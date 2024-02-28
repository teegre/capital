package main

import rl "vendor:raylib"
import "entities"
import "room"
import "scene"
import "capsules"

love := true

player: ^entities.Character
enemy: ^entities.Character
nurse: ^entities.Character

the_scene: ^scene.Scene

frame_count: int = 0

init :: proc() {

  rl.InitWindow(scene.WIDTH, scene.HEIGHT, "YAY!")
  rl.SetTargetFPS(60)
  rl.SetExitKey(rl.KeyboardKey(0))

  player = entities.new_player("virginie", "capital/resources/virginie2.png")

  capsules.add_capsule_to_inventory(player, "attack")
  capsules.add_capsule_to_inventory(player, "shield")
  capsules.add_capsule_to_inventory(player, "relieve")

  player.max_frame = 3
  player.frame_step = 1
  player.size = {15, 19}
  player.layer = 1

  nurse = entities.new_npc("nurse", "capital/resources/nurse-a.png")
  nurse.frame = 1
  nurse.frame_step = 1
  nurse.max_frame = 3
  nurse.size = {15, 21}

  enemy = entities.new_enemy("square", "capital/resources/enemy.png")

  capsules.add_capsule_to_inventory(enemy, "attack")
  capsules.add_capsule_to_inventory(enemy, "shield")
  capsules.add_capsule_to_inventory(enemy, "relieve")

  enemy.max_frame = 2
  enemy.frame_step = 1
  enemy.size = {15, 23}

  the_scene = new(scene.Scene)

  scene.add_to_scene(the_scene, room.make_room("capital/resources/room-d.png", scene.WIDTH, scene.HEIGHT, 7, 7, scene.TILE_SIZE))
  scene.add_to_scene(the_scene, player)
  scene.add_to_scene(the_scene, enemy)
  scene.add_to_scene(the_scene, nurse)

  player.src = {0, 0, player.size.w, player.size.h}
  player.dest = {
    (scene.WIDTH / 2)-(scene.TILE_SIZE / 2),
    the_scene.room.corridor.height + the_scene.room.corridor.y - player.size.h - (scene.TILE_SIZE / 2),
    player.size.w,
    player.size.h,
  }
  player.direction = .UP

  nurse.src = {0, 0, nurse.size.w, nurse.size.h}
  nurse.dest = {
    the_scene.room.room.x + scene.TILE_SIZE,
    the_scene.room.room.y + the_scene.room.room.height + (nurse.size.h / 4),
    nurse.size.w,
    nurse.size.h,
  }

  enemy.src = {0, 0, enemy.size.w, enemy.size.h}
  enemy.dest = {
    the_scene.room.area.x + (2 * scene.TILE_SIZE),
    the_scene.room.area.y + scene.TILE_SIZE,
    enemy.size.w,
    enemy.size.h,
  }
}

update :: proc() {
  scene.update_scene(the_scene)

  if player.moving  && !the_scene.room.entrance_opening && !the_scene.room.exit_opening {
    switch player.direction {
    case .UP:
      player.dest.y -= player.speed
    case .RIGHT:
      player.dest.x += player.speed
    case .LEFT:
      player.dest.x -= player.speed
    case .DOWN:
      player.dest.y += player.speed
    }
  }

  if frame_count % 6 == 0 {
    scene.animate(the_scene)
  }

  frame_count += 1

  love = !rl.WindowShouldClose()
}

render :: proc() {
  rl.BeginDrawing()
    rl.ClearBackground(rl.Color{40, 40, 40, 255})
    rl.BeginMode2D(the_scene.camera)
      draw()
    rl.EndMode2D()
  rl.EndDrawing()
}

draw :: proc() {
  rl.DrawRectangleLines(0, 0, i32(rl.GetScreenWidth()), i32(rl.GetScreenHeight()), rl.RED)
  scene.render_scene(the_scene)
}

input :: proc() {
  using rl.KeyboardKey
    if rl.IsKeyDown(LEFT_SHIFT) {
      player.speed = 2
    } else {
      player.speed = 0.5
    }
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
      the_scene.room.entrance_locked = !the_scene.room.entrance_locked
      the_scene.room.exit_locked = !the_scene.room.exit_locked
    } else if rl.IsKeyPressed(W) {
      the_scene.zoom += 0.1
    } else if rl.IsKeyPressed(Q) {
      the_scene.zoom -= 0.1
    }
}

quit :: proc() {
  delete_dynamic_array(the_scene.characters)
  entities.delete_character(player)
  entities.delete_character(enemy)
  entities.delete_character(nurse)
  entities.delete_room(the_scene.room)
  free(the_scene)
  rl.CloseWindow()
}

main :: proc() {
  init()

  for love {
    input()
    update()
    render()
  }

  quit()
}
