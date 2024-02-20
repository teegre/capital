package tests

import "core:testing"
import "core:mem"
import "core:fmt"

// _test_memory_leak :: proc() {
// }

// @test
// test_memory_leak :: proc(t: ^testing.T) {
//   using testing
//   track: mem.Tracking_Allocator
//   mem.tracking_allocator_init(&track, context.allocator)
//   defer mem.tracking_allocator_destroy(&track)
//   context.allocator = mem.tracking_allocator(&track)

//   _test_memory_leak()

//   expect(t, len(track.allocation_map) == 0 && len(track.bad_free_array) == 0)

//   for _, leak in track.allocation_map {
// 	  fmt.printf("%v leaked %m\n", leak.location, leak.size)
//   }
//   for bad_free in track.bad_free_array {
// 	  fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
//   }
// }
