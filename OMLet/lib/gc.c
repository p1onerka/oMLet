#include "boxing.h"
#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _GNU_SOURCE
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <ucontext.h>
#define HEAP_INIT_SIZE 1000
#include <stdbool.h>

typedef enum {
  T_UNBOXED = 0,
  T_CLOSURE = 1,
} tag_t;

typedef enum {
  COLOR_UNMARKED = 0,
  COLOR_MARKED = 1,
} color_t;

typedef struct {
  tag_t tag;     // object type
  color_t color; // GC mark state
  uint16_t size; // payload size in 8-byte words
  uint32_t pad;  // alignment
} box_header_t;

typedef struct {
  uint8_t *start;
  size_t size;
  size_t offset;
} omletHeap_t;

omletHeap_t heap_from;
omletHeap_t heap_to;
omletHeap_t *cur_heap_ptr = &heap_from;

omletHeap_t *alloc_heap(size_t size) {
  uint8_t *start = (uint8_t *)malloc(size);
  omletHeap_t *heap_ptr = (omletHeap_t *)malloc(sizeof(*heap_ptr));
  heap_ptr->start = start;
  heap_ptr->size = size;
  heap_ptr->offset = 0;
  return heap_ptr;
}

void init_heap(size_t size) {
  heap_from.start = malloc(size);
  heap_from.size = size;
  heap_from.offset = 0;

  heap_to.start = malloc(size);
  heap_to.size = size;
  heap_to.offset = 0;

  cur_heap_ptr = &heap_from;
  printf("cur_heap_ptr init: %p\n", (void *)cur_heap_ptr->start);
}

static inline void *get_current_sp() {
  void *ret;
  asm volatile("mv %0, sp\n" : [ret] "=r"(ret));
  return ret;
}

uint64_t **stack_bottom = NULL;
uint64_t **stack_top;

void init_start_heap() {
  stack_bottom = get_current_sp();
  printf("Stack bottom init: %p\n", (void *)stack_bottom);
  init_heap(HEAP_INIT_SIZE);
}

void free_heap() {
  // free(cur_heap_ptr->start);
  // free(cur_heap_ptr);
}

uintptr_t get_heap_start() { return ((uintptr_t)cur_heap_ptr->start << 1) + 1; }

uintptr_t get_heap_fin() {
  return ((uintptr_t)(cur_heap_ptr->start + cur_heap_ptr->size) << 1) + 1;
}

size_t get_heap_free_size() {
  return ((cur_heap_ptr->size - cur_heap_ptr->offset) << 1) + 1;
}

// void *malloc_on_current_heap(size_t size) {
//   void *free_ptr = cur_heap_ptr->start + cur_heap_ptr->offset;
//   cur_heap_ptr->offset += size;
//   return free_ptr;
// }

static inline box_header_t *get_header(uint64_t *obj) {
  return ((box_header_t *)obj) - 1;
}

static inline bool on_cur_heap(uint64_t *ptr) {
  uintptr_t addr = (uintptr_t)ptr;
  uintptr_t start = (uintptr_t)cur_heap_ptr->start;
  uintptr_t end = start + cur_heap_ptr->size;

  return addr >= start && addr < end;
}

static uint64_t *copy_object(uint64_t *obj, omletHeap_t *from_heap,
                             omletHeap_t *to_heap) {
  box_header_t *old_hdr = get_header(obj);

  if (old_hdr->color == COLOR_MARKED) {
    return obj; // pointer already updated elsewhere
  }

  size_t obj_bytes = sizeof(box_header_t) + old_hdr->size * sizeof(uint64_t);

  if (to_heap->offset + obj_bytes > to_heap->size) {
    fprintf(stderr, "[GC ERROR] Out of memory during copy_object\n");
    exit(1);
  }

  uint8_t *dest = to_heap->start + to_heap->offset;
  to_heap->offset += obj_bytes;

  box_header_t *new_hdr = (box_header_t *)dest;
  *new_hdr = *old_hdr;

  uint64_t *new_obj = (uint64_t *)(new_hdr + 1);

  // copy payload
  if (old_hdr->tag == T_CLOSURE) {
    printf("wooow\n");
    for (uint16_t i = 0; i < old_hdr->size; i++) {
      new_obj[i] = obj[i];
    }
  } else {
    memcpy(new_obj, obj, old_hdr->size * sizeof(uint64_t));
  }

  old_hdr->color = COLOR_MARKED;
  printf("[GC COPY] old_obj=%p -> new_obj=%p size=%u words tag=%d\n",
         (void *)obj, (void *)new_obj, old_hdr->size, old_hdr->tag);
  return new_obj;
}

static void update_pointers(uint64_t *obj, omletHeap_t *from_heap,
                        omletHeap_t *to_heap) {
  // printf("start\n");
  box_header_t *hdr = get_header(obj);

  if (hdr->tag != T_CLOSURE) {
    return;
  }

  for (uint16_t i = 0; i < hdr->size; i++) {
    uint64_t *field_ptr = (uint64_t *)obj[i];

    if (!on_cur_heap(field_ptr)) {
      // printf("not on heap\n");
      continue;
    }

    box_header_t *field_hdr = get_header(field_ptr);
    if (field_hdr->color == COLOR_MARKED) {
      continue;
    }

    uint64_t *copied_obj = copy_object(field_ptr, from_heap, to_heap);
    // printf("end\n");
    obj[i] = (uint64_t)copied_obj;

    // recursively update internal pointers of the copied object
    update_pointers(copied_obj, from_heap, to_heap);
  }
}

static void mark_and_copy() {
  stack_top = get_current_sp();
  if (stack_bottom == NULL || stack_top == NULL) {
    fprintf(stderr, "[GC] Stack not initialized properly\n");
    return;
  }
  // printf("stack_bottom: %p\n", (void *)stack_bottom);
  // printf("stack_top: %p\n", (void *)stack_top);
  printf("cur_heap_ptr in mark_and_copy: %p\n", (void *)cur_heap_ptr->start);

  omletHeap_t *from_heap = (cur_heap_ptr == &heap_from) ? &heap_to : &heap_from;
  omletHeap_t *to_heap = cur_heap_ptr;

  for (uint64_t **ptr = stack_top; ptr <= stack_bottom; ptr++) {
    // printf("hello %p", *ptr);
    uint64_t *obj_ptr = *ptr;

    if (!on_cur_heap((uint64_t *)obj_ptr)) {
      continue;
    }
    printf("hello %p\n", *ptr);

    box_header_t *hdr = get_header((uint64_t *)obj_ptr);
    if (hdr->color == COLOR_MARKED) {
      continue;
    }

    uint64_t *copied_obj = copy_object((uint64_t *)obj_ptr, from_heap, to_heap);

    *ptr = (uint64_t *)copied_obj;

    update_pointers(copied_obj, from_heap, to_heap);
  }
}

void collect(void) {
  omletHeap_t *from_heap = cur_heap_ptr;
  omletHeap_t *to_heap = (cur_heap_ptr == &heap_from) ? &heap_to : &heap_from;
  to_heap->offset = 0;
  cur_heap_ptr = to_heap;

  mark_and_copy();
  printf("end\n");
}

void *omlet_malloc(size_t size, tag_t tag) {
  size_t size_in_words =
      ((uint64_t)size + sizeof(uint64_t) - 1) / sizeof(uint64_t);
  size_t total_size = sizeof(box_header_t) + size;
  if (cur_heap_ptr->offset + total_size > cur_heap_ptr->size) {
    collect(); // run GC

    printf("size1 %zu\n", cur_heap_ptr->offset + total_size);
    printf("size2 %zu\n", cur_heap_ptr->size);
    if (cur_heap_ptr->offset + total_size > cur_heap_ptr->size) {
      fprintf(stderr, "Out of memory in omlet_malloc\n");
      exit(1);
    }
  }
  uint8_t *ptr = cur_heap_ptr->start + cur_heap_ptr->offset;
  cur_heap_ptr->offset += total_size;
  box_header_t *header = (box_header_t *)ptr;
  header->tag = tag;
  header->color = COLOR_UNMARKED;
  header->size = (uint16_t)size_in_words;
  header->pad = 0;
  void *payload = (void *)(header + 1);
  // printf("[GC ALLOC] tag=%d, color=%d, size=%u words \n", header->tag,
  //        header->color, header->size);
  // printf("            header=%p  payload=%p\n", (void *)header, payload);
  // printf("            heap_offset=%zu / %zu bytes (free=%zu bytes)\n",
  //        cur_heap_ptr->offset, cur_heap_ptr->size,
  //        cur_heap_ptr->size - cur_heap_ptr->offset);
  // printf("--------------------------------------------------------\n");

  // printf("payload %p alloced\n", payload);
  return payload;
}
