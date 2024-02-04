package tests

import "core:testing"
import "core:mem"
import "core:fmt"
import "../capsules"
import "../entities"
import "../rng"
import "../actions"

a: ^entities.Character
b: ^entities.Character

seed: string
u_seed: u64

init_characters :: proc() {
  a = entities.new_character()
  b = entities.new_character()
}

@test
test_steroids :: proc(t: ^testing.T) {
  using entities, capsules, actions, rng, testing
  seed, _ = new_seed()
  set_seed(seed)
  fmt.println("SEED:", SEED)
  init_characters()
  a.name = "A"
  b.name = "B"
  defer delete_character(a)
  defer delete_character(b)
  new_capsule(a, "steroids")
  response := perform_action(a, b, "steroids")
  expect(t, a.strength_mul == 2)
  detach(a, "steroids")
  expect(t, a.strength_mul == 1)
}

@test
test_berserk :: proc(t: ^testing.T) {
  using entities, capsules, actions, rng, testing
  set_seed("0UP96JGD")
  fmt.println("SEED:", SEED)
  init_characters()
  a.name = "A"
  b.name = "B"
  defer delete_character(a)
  defer delete_character(b)
  new_capsule(a, "attack")
  new_capsule(a, "berserk")
  new_capsule(b, "attack")
  a.agility = 4
  a.critical_rate = 100
  b.agility = 5
  a.critical_rate = 100
  perform_action(a, b, "berserk")
  response := perform_action(a, b, "attack")
  expect(t, response.value == response.initial_value * 2)
  response = perform_action(b, a, "attack")
  expect(t, a.pain == 0 && .NOPAIN in response.flags)
}

@test
test_priority :: proc(t: ^testing.T) {
  using entities, capsules, actions, rng, testing
  set_seed("JFWT9BZQ")
  fmt.println("SEED:", SEED)
  init_characters()
  defer delete_character(a)
  defer delete_character(b)
  a.name = "a"
  b.name = "b"
  a.health = 48
  a.agility = 2
  new_capsule(a, "attack")
  new_capsule(a, "leech")
  new_capsule(b, "attack")
  new_capsule(b, "shield")
  new_capsule(b, "wall")
  a_response := perform_action(a, b, "leech")
  b_response := perform_action(b, a, "shield")
  b_response = perform_action(b, a, "wall")
  expected_list : [3]string = { "wall", "shield", "leech"}
  actual_list: [3]string
  for capsule, i in b.active_capsules {
    actual_list[i] = capsule.name
  }
  expect(t, actual_list == expected_list) 
  a_response = perform_action(a, b, "attack")
  expect(t, .NODAMAGE in a_response.flags)
  a_response = perform_action(a, b, "attack")
  expect(t, len(b.active_capsules) == 1 && a.health == 50)
  expect(t, (.PARTIALBLOCK in a_response.flags) && .HEAL in a_response.flags)
}

@test
test_rng :: proc(t: ^testing.T) {
  using rng, testing, entities
  init_characters()
  defer delete_character(a)
  defer delete_character(b)
  seed, u_seed = new_seed()
  fmt.printf("SEED: %s/%d\n", seed, u_seed)
  set_seed(seed)
  roll1 := roll()
  roll2 := roll()
  s1 := success(a, b)
  s2 := success(b, a)
  set_seed(seed)
  roll3 := roll()
  roll4 := roll()
  s3 := success(a, b)
  s4 := success(b, a)
  fmt.printf("ROLL: %d, %d; %d, %d\n", roll1, roll2, roll3, roll4)
  fmt.printf("SUCCESS: %v, %v; %v, %v\n", s1, s2, s3, s4)
  expect(t, roll1 == roll3 && roll2 == roll4)
  expect(t, s1 == s3 && s2 == s4)
}

@test
test_shield :: proc(t: ^testing.T) {
  using entities, capsules, rng, actions, testing
  set_seed("DPPA9FIF")
  fmt.println("SEED:", SEED)
  init_characters()
  defer delete_character(a)
  defer delete_character(b)
  new_capsule(a, "shield")
  new_capsule(b, "attack")
  perform_action(a, b, "shield")
  perform_action(b, a, "attack")
  expect(t, a.shield == 0 && a.health == 46)
}

@test
test_wall :: proc(t: ^testing.T) {
  using entities, rng, capsules, actions, testing
  set_seed("XI3XVGJY")
  fmt.println("SEED:", SEED)
  init_characters()
  a.agility = 6
  a.strength = 5
  a.critical_rate = 100
  b.defense = 10
  a.name = "PLAYER"
  b.name = "ENEMY"
  new_capsule(a, "attack")
  new_capsule(b, "shield")
  new_capsule(b, "wall")
  perform_action(b, a, "wall")
  perform_action(b, a, "shield")
  perform_action(b, a, "shield")
  perform_action(a, b, "attack")
  expect(t, b.health == 50 && b.shield == 81)
  perform_action(a, b, "attack")
  perform_action(a, b, "attack")
  expect(t, b.health == 47 && b.shield == 0)
}

// @test
// test_combat :: proc(t: ^testing.T) {
//   using entities, actions, capsules, rng, testing
//   seed, u_seed = new_seed()
//   fmt.printf("SEED: %s/%d\n", seed, u_seed)
//   set_seed(seed)
//   init_characters()
//   defer delete_character(a)
//   defer delete_character(b)
//   a.name = "P1"
//   b.name = "P2"
//   new_capsule(a, "attack")
//   new_capsule(a, "shield")
//   new_capsule(a, "relieve")
//   new_capsule(b, "attack")
//   new_capsule(b, "shield")
//   new_capsule(b, "relieve")
//   pdmg, edmg := 0, 0
//   pflags: CapsuleFlags
//   eflags: CapsuleFlags
//   for (.DEAD not_in eflags && .DEAD not_in pflags) {
//     pdmg, pflags = perform_action(a, b, "attack")
//     if b.health == 0 {
//       break
//     }
//     edmg, eflags = perform_action(b, a, "attack")
//   }
//   expect(t, a.health == 0 || b.health == 0)
//   if a.health == 0 {
//    fmt.println("P1 DIED")
//   } else {
//     fmt.println("P2 DIED!")
//   }
// }

// @test
// test_action_list :: proc(t: ^testing.T) {
//   using entities, capsules, testing
//   init_characters()
//   new_capsule(a, "attack")
//   new_capsule(a, "shield")
//   new_capsule(a, "relieve")
//   action_list := character_actions(a)
//   defer delete_dynamic_array(action_list)
//   expect(t, len(action_list) == 2 && action_list[0] == "attack" && action_list[1] == "shield")
// }

@test
test_leech :: proc(t: ^testing.T) {
  using entities, actions, capsules, rng, testing
  set_seed("LELPIWCW")
  fmt.println("SEED: LELPIWCW")
  init_characters()
  a.name = "Player"
  a.health = 25
  b.name = "Enemy"
  new_capsule(a, "attack")
  new_capsule(a, "leech")
  new_capsule(b, "shield")
  defer delete_character(a)
  defer delete_character(b)
  p_response, e_response: Response
  p_response = perform_action(a, b, "leech")
  expect(t, b.active_capsules[0].name == "leech")
  e_response =  perform_action(b, a, "shield")
  expect(t, b.shield > 0, "Shield did not work as expected...")
  p_response = perform_action(a, b, "leech")
  expect(t, p_response.value == 0 && .NOCAPSULE in p_response.flags, "Player leech has not been deactivated...")
  perform_action(a, b, "attack")
  expect(t, a.health == 28 && b.health == 47, "leech did not work...")
}

@test
test_poison :: proc(t: ^testing.T) {
  using rng, entities, capsules, actions, testing
  set_seed("B4PGIDQ6")
  fmt.println("SEED:", SEED)
  init_characters()
  a.name = "A"
  b.name = "B"
  defer delete_character(a)
  defer delete_character(b)
  new_capsule(a, "attack")
  new_capsule(a, "poison")
  new_capsule(b, "attack")
  new_capsule(b, "shield")
  perform_action(a, b, "poison")
  perform_action(b, a, "attack")
  perform_action(a, b, "shield")
  perform_action(b, a, "shield")
  perform_action(a, b, "shield")
  perform_action(b, a, "attack")
  capsule := get_active_capsule(b, "poison")
  expect(t, b.health == 47 && capsule == nil)
}

_test_memory_leak :: proc() {
  using entities, actions, capsules, rng
  fmt.println("SEED: RABL5NC2")
  set_seed("RABL5NC2")
  init_characters()
  a.name = "P1"
  b.name = "P2"
  new_capsule(a, "attack")
  new_capsule(a, "shield")
  new_capsule(a, "relieve")
  new_capsule(b, "attack")
  new_capsule(b, "shield")
  new_capsule(b, "relieve")
  defer delete_character(a)
  defer delete_character(b)
  p_response, e_response: Response
  for (.DEAD not_in p_response.flags && .DEAD not_in e_response.flags) {
    if a.pain_rate == 525 {
      p_response = perform_action(a, b, "relieve")
    } else {
      e_response = perform_action(a, b, "attack")
    }
    if b.health == 0 {
      break
    }
    e_response = perform_action(b, a, "attack")
  }
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

@test
test_new_attack :: proc(t: ^testing.T) {
  using rng, entities, capsules, actions, testing
  // seed, _ = new_seed()
  // set_seed(seed)
  set_seed("9EU0Q89N")
  fmt.println("SEED:", SEED)
  a := new_character()
  b := new_character()
  a.name = "A"
  b.name = "B"
  b.agility = 3
  defer delete_character(a)
  defer delete_character(b)
  new_capsule(a, "attack")
  new_capsule(a, "shield")
  new_capsule(b, "attack")
  new_capsule(b, "shield")
  perform_action(a, b, "shield")
  perform_action(b, a, "attack")
  perform_action(a, b, "attack")
  perform_action(b, a, "attack")
  perform_action(b, a, "attack")
  perform_action(b, a, "attack")
  perform_action(b, a, "attack")
  expect(t, len(a.active_capsules) == 0, "A shield still attached")
  expect(t, len(b.active_capsules) == 0, "B shield still attached")
}

@test
test_relieve :: proc(t: ^testing.T) {
  using entities, actions, capsules, rng, testing

  fmt.println("SEED: RABL5NC2 (defined)")
  set_seed("RABL5NC2")

  a := new_character()
  b := new_character()
  defer delete_character(a)
  defer delete_character(b)

  new_capsule(a, "attack")
  new_capsule(a, "shield")
  new_capsule(a, "relieve")
  new_capsule(b, "attack")
  new_capsule(b, "shield")
  new_capsule(b, "relieve")

  a_response, b_response: Response

  for (.DEAD not_in a_response.flags && .DEAD not_in b_response.flags) {
    if a.pain_rate == 525 {
      a_response = perform_action(a, b, "relieve")
    } else {
      a_response = perform_action(a, b, "attack")
    }
    if b.health == 0 {
      break
    }
    b_response = perform_action(b, a, "attack")
  }

  expect(t, b.health == 0 && a.health == 13)
}
