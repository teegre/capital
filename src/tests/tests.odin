package tests

import "core:testing"
import "core:mem"
import "core:fmt"
import "../capsules"
import "../entities"
import "../rng"
import "../actions"


TPlayer: ^entities.Character
TEnemy: ^entities.Character

seed: string
u_seed: u64

@test
test_rng :: proc(t: ^testing.T) {
  using rng, testing, entities
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  seed, u_seed = new_seed()
  fmt.printf("SEED: %s/%d\n", seed, u_seed)
  set_seed(seed)
  roll1 := roll()
  roll2 := roll()
  s1 := success(TPlayer, TEnemy)
  s2 := success(TEnemy, TPlayer)
  set_seed(seed)
  roll3 := roll()
  roll4 := roll()
  s3 := success(TPlayer, TEnemy)
  s4 := success(TEnemy, TPlayer)
  fmt.printf("ROLL: %d, %d; %d, %d\n", roll1, roll2, roll3, roll4)
  fmt.printf("SUCCESS: %v, %v; %v, %v\n", s1, s2, s3, s4)
  expect(t, roll1 == roll3 && roll2 == roll4)
  expect(t, s1 == s3 && s2 == s4)
}

@test
test_characters :: proc(t: ^testing.T) {
  using entities
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  TPlayer.name = "Teegre"
  TEnemy.name = "Nemesis"
  testing.expect(t, TPlayer.name == "Teegre" && TEnemy.name == "Nemesis")
}

@test
test_new_capsule :: proc(t: ^testing.T) {
  using capsules, entities, testing
  TPlayer = new_character()
  defer delete_character(TPlayer)
  register_capsule(TPlayer, get_new_capsule("attack"))
  expect(t, TPlayer.inventory[0].name == "attack")
}

@test
test_attack :: proc(t: ^testing.T) {
  using entities, capsules, actions, rng, testing
  seed, u_seed = new_seed()
  fmt.printf("SEED: %s/%d\n", seed, u_seed)
  set_seed(seed)
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  ok := register_capsule(TPlayer, get_new_capsule("attack"))
  expect(t, TPlayer.inventory[0].name == "attack")
  expect(t, ok == true, "Could not register capsule!")
  dmg, flags := perform_action(TPlayer, TEnemy, "attack")
  fmt.println(dmg, flags)
  expect(t, TEnemy.health < 50 || .MISS in flags)
}

@test
test_no_capsule :: proc(t: ^testing.T) {
  using entities, actions, rng, testing
  seed, u_seed = new_seed()
  fmt.printf("SEED: %s/%d\n", seed, u_seed)
  set_seed(seed)
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  dmg, flags := perform_action(TPlayer, TEnemy, "attack")
  expect(t, dmg == 0 && .NOCAPSULE in flags) 
}

@test
test_combat :: proc(t: ^testing.T) {
  using entities, actions, capsules, rng, testing
  seed, u_seed = new_seed()
  fmt.printf("SEED: %s/%d\n", seed, u_seed)
  set_seed(seed)
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  register_capsule(TPlayer, get_new_capsule("attack"))
  register_capsule(TPlayer, get_new_capsule("shield"))
  register_capsule(TPlayer, get_new_capsule("relieve"))
  register_capsule(TEnemy, get_new_capsule("attack"))
  register_capsule(TEnemy, get_new_capsule("shield"))
  register_capsule(TEnemy, get_new_capsule("relieve"))
  pdmg, edmg := 0, 0
  pflags: CapsuleFlags
  eflags: CapsuleFlags
  for (.DEAD not_in eflags && .DEAD not_in pflags) {
    pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
    if TEnemy.health == 0 {
      break
    }
    edmg, eflags = perform_action(TEnemy, TPlayer, "attack")
  }
  expect(t, TPlayer.health == 0 || TEnemy.health == 0)
  if TPlayer.health == 0 {
   fmt.println("P1 DIED")
  } else {
    fmt.println("P2 DIED!")
  }
}

@test
test_relieve :: proc(t: ^testing.T) {
  using entities, actions, capsules, rng, testing
  fmt.println("SEED: RABL5NC2 (defined)")
  set_seed("RABL5NC2")
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  register_capsule(TPlayer, get_new_capsule("attack"))
  register_capsule(TPlayer, get_new_capsule("shield"))
  register_capsule(TPlayer, get_new_capsule("relieve"))
  register_capsule(TEnemy, get_new_capsule("attack"))
  register_capsule(TEnemy, get_new_capsule("shield"))
  register_capsule(TEnemy, get_new_capsule("relieve"))
  pdmg, edmg := 0, 0
  pflags: CapsuleFlags
  eflags: CapsuleFlags
  for (.DEAD not_in eflags && .DEAD not_in pflags) {
    if TPlayer.pain_rate == 525 {
      pdmg, pflags = perform_action(TPlayer, TEnemy, "relieve")
    } else {
      pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
    }
    if TEnemy.health == 0 {
      break
    }
    edmg, eflags = perform_action(TEnemy, TPlayer, "attack")
  }
  expect(t, TEnemy.health == 0 && TPlayer.health == 13)
  fmt.println("P2 DIED!")
}

_main :: proc() {
  using entities, actions, capsules, rng
  fmt.println("SEED: RABL5NC2", seed)
  set_seed("RABL5NC2")
  TPlayer = new_character()
  TEnemy = new_character()
  register_capsule(TPlayer, get_new_capsule("attack"))
  register_capsule(TPlayer, get_new_capsule("shield"))
  register_capsule(TPlayer, get_new_capsule("relieve"))
  register_capsule(TEnemy, get_new_capsule("attack"))
  register_capsule(TEnemy, get_new_capsule("shield"))
  register_capsule(TEnemy, get_new_capsule("relieve"))
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  pdmg, edmg := 0, 0
  pflags: CapsuleFlags
  eflags: CapsuleFlags
  for (.DEAD not_in eflags && .DEAD not_in pflags) {
    if TPlayer.pain_rate == 525 {
      pdmg, pflags = perform_action(TPlayer, TEnemy, "relieve")
    } else {
      pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
    }
    if TEnemy.health == 0 {
      break
    }
    edmg, eflags = perform_action(TEnemy, TPlayer, "attack")
  }
  fmt.println("P2 DIED!")
}

main :: proc() {
  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  defer mem.tracking_allocator_destroy(&track)
  context.allocator = mem.tracking_allocator(&track)

  _main()

  for _, leak in track.allocation_map {
	  fmt.printf("%v leaked %m\n", leak.location, leak.size)
  }
  for bad_free in track.bad_free_array {
	  fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
  }
}
