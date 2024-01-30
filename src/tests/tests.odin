package tests

import "core:testing"
import "core:log"
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
  using entities, testing
  TPlayer = new_character()
  TEnemy = new_character()
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  TPlayer.name = "Teegre"
  TEnemy.name = "Nemesis"
  expect(t, TPlayer.name == "Teegre" && TEnemy.name == "Nemesis")
}

@test
test_new_capsule :: proc(t: ^testing.T) {
  using capsules, entities, testing
  TPlayer = new_character()
  defer delete_character(TPlayer)
  ok := new_capsule(TPlayer, "attack")
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
  ok := new_capsule(TPlayer, "attack")
  expect(t, ok == true, "Could not register capsule!")
  expect(t, TPlayer.inventory[0].name == "attack")
  dmg, flags := perform_action(TPlayer, TEnemy, "attack")
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
  TPlayer.name = "P1"
  TEnemy.name = "P2"
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "shield")
  new_capsule(TPlayer, "relieve")
  new_capsule(TEnemy, "attack")
  new_capsule(TEnemy, "shield")
  new_capsule(TEnemy, "relieve")
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
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "shield")
  new_capsule(TPlayer, "relieve")
  new_capsule(TEnemy, "attack")
  new_capsule(TEnemy, "shield")
  new_capsule(TEnemy, "relieve")
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

@test
test_action_list :: proc(t: ^testing.T) {
  using entities, capsules, testing
  TPlayer = new_character()
  defer delete_character(TPlayer)
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "shield")
  new_capsule(TPlayer, "relieve")
  action_list := character_actions(TPlayer)
  defer delete_dynamic_array(action_list)
  expect(t, len(action_list) == 2 && action_list[0] == "attack" && action_list[1] == "shield")
}

@test
test_leech :: proc(t: ^testing.T) {
  using entities, actions, capsules, rng, testing
  set_seed("LELPIWCW")
  fmt.println("SEED: LELPIWCW")
  TPlayer = new_character()
  TEnemy = new_character()
  TPlayer.name = "Player"
  TPlayer.health = 25
  TEnemy.name = "Enemy"
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "leech")
  new_capsule(TEnemy, "shield")
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  pdmg, edmg :=  0, 0
  pflags, eflags: CapsuleFlags
  pdmg, pflags = perform_action(TPlayer, TEnemy, "leech")
  expect(t, TEnemy.active_capsules[0].name == "leech")
  edmg, eflags =  perform_action(TEnemy, TPlayer, "shield")
  expect(t, TEnemy.shield > 0, "Shield did not work as expected...")
  pdmg, pflags = perform_action(TPlayer, TEnemy, "leech")
  expect(t, pdmg == 0 && .NOCAPSULE in pflags, "Player leech has not been deactivated...")
  pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
  expect(t, TPlayer.health == 28 && TEnemy.health == 47, "leech did not work...")
  detach(TEnemy, "leech")
}

_test_memory_leak :: proc() {
  using entities, actions, capsules, rng
  fmt.println("SEED: RABL5NC2")
  set_seed("RABL5NC2")
  TPlayer = new_character()
  TEnemy = new_character()
  TPlayer.name = "P1"
  TEnemy.name = "P2"
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "shield")
  new_capsule(TPlayer, "relieve")
  new_capsule(TEnemy, "attack")
  new_capsule(TEnemy, "shield")
  new_capsule(TEnemy, "relieve")
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

@test
test_poison :: proc(t: ^testing.T) {
  using rng, entities, capsules, actions, testing
  set_seed("B4PGIDQ6")
  fmt.println("SEED:", SEED)
  TPlayer = new_character()
  TEnemy = new_character()
  TPlayer.name = "Player"
  TEnemy.name = "Enemy"
  defer delete_character(TPlayer)
  defer delete_character(TEnemy)
  new_capsule(TPlayer, "attack")
  new_capsule(TPlayer, "poison")
  new_capsule(TEnemy, "attack")
  new_capsule(TEnemy, "shield")
  pdmg, edmg: int
  pflags, eflags: CapsuleFlags
  pdmg, pflags = perform_action(TPlayer, TEnemy, "poison")
  fmt.println("> Player", pdmg, pflags)
  edmg, eflags = perform_action(TEnemy, TPlayer, "attack")
  fmt.println("> Enemy", edmg, eflags)
  pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
  fmt.println("> Player", pdmg, pflags)
  edmg, eflags = perform_action(TEnemy, TPlayer, "shield")
  fmt.println("> Enemy", edmg, eflags)
  pdmg, pflags = perform_action(TPlayer, TEnemy, "attack")
  fmt.println("> Player", pdmg, pflags)
  edmg, eflags = perform_action(TEnemy, TPlayer, "attack")
  fmt.println("> Enemy", edmg, eflags)
  fmt.println(TPlayer.health, TPlayer.pain_rate, TEnemy.health, TEnemy.pain_rate)
  expect(t, TEnemy.health == 46 && len(TEnemy.active_capsules) == 0)
}

@test
test_memory_leak :: proc(t: ^testing.T) {
  using testing
  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  defer mem.tracking_allocator_destroy(&track)
  context.allocator = mem.tracking_allocator(&track)

  _test_memory_leak()

  expect(t, len(track.allocation_map) == 0 && len(track.bad_free_array) == 0)

  for _, leak in track.allocation_map {
	  fmt.printf("%v leaked %m\n", leak.location, leak.size)
  }
  for bad_free in track.bad_free_array {
	  fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
  }
}
