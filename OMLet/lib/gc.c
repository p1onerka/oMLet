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

typedef uint8_t tag_t;
enum {
  T_UNBOXED = 0,
  T_CLOSURE = 1,
};

typedef uint8_t color_t;
enum {
  COLOR_UNMARKED = 0,
  COLOR_MARKED = 1,
};

typedef struct {
  tag_t tag;     // object type
  color_t color; // GC mark state
  uint16_t size; // payload size in 8-byte words
  uint32_t pad;  // alignment
} box_header_t;

void print_box_header(const box_header_t *hdr) {
  if (!hdr) {
    printf("<box_header: NULL>\n");
    return;
  }

  printf("Box header at %p:\n", (void *)hdr);
  printf("  tag   = %d", hdr->tag);
  switch (hdr->tag) {
  case T_CLOSURE:
    printf(" (T_CLOSURE)\n");
    break;
  default:
    printf(" (UNKNOWN)\n");
    break;
  }
  printf("  color = %d (%s)\n", hdr->color,
         hdr->color == COLOR_MARKED ? "MARKED" : "UNMARKED");
  printf("  size  = %u words (%lu bytes)\n", hdr->size,
         (unsigned long)(hdr->size * sizeof(uint64_t)));
  printf("  pad   = 0x%x\n", hdr->pad);
  printf("----------------------------------------\n");
}

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
  // printf("heap_from: %p .. %p\n", (void *)heap_from.start,
  //        (void *)(heap_from.start + heap_from.size));
  // printf("heap_to:   %p .. %p\n", (void *)heap_to.start,
  //        (void *)(heap_to.start + heap_to.size));
  // printf("cur_heap_ptr init: %p\n", (void *)cur_heap_ptr->start);
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
  // printf("Stack bottom init: %p\n", (void *)stack_bottom);
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

static inline bool on_heap(uint64_t *ptr, omletHeap_t *heap) {
  uintptr_t addr = (uintptr_t)ptr;
  uintptr_t start = (uintptr_t)heap->start;
  uintptr_t end = start + heap->size;
  return addr >= start && addr < end;
}

static uint64_t *copy_object(uint64_t *obj, omletHeap_t *from_heap,
                             omletHeap_t *to_heap) {
  box_header_t *old_hdr = get_header(obj);
  // printf("[COPY START] obj=%p, size=%u, tag=%d, color=%d\n", (void *)obj,
  //        old_hdr->size, old_hdr->tag, old_hdr->color);

  // print_box_header(old_hdr);c
  if (old_hdr->color == COLOR_MARKED) {
    // printf("[COPY SKIP] Already marked\n");
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
  // printf("[COPY PAYLOAD] new_obj=%p\n", (void *)new_obj);

  // printf("tag %d\n", old_hdr->tag);
  // copy payload
  if (old_hdr->tag == T_CLOSURE) {
    // printf("tag1 %d\n", old_hdr->tag);
    // printf("wooow\n");
    for (uint16_t i = 0; i < old_hdr->size; i++) {
      // printf("tag2 %d\n", old_hdr->tag);
      // printf("[COPY WORD] old_obj[%u]=%p\n", i, (void *)obj[i]);
      new_obj[i] = obj[i];
      // printf("tag2 %d\n", old_hdr->tag);
    }
    // printf("tag3 %d\n", old_hdr->tag);
    // print_box_header(old_hdr);
    // printf("[GC COPY] old_obj=%p -> new_obj=%p size=%u words tag=%d\n",
    //        (void *)obj, (void *)new_obj, old_hdr->size, old_hdr->tag);
  } else {
    memcpy(new_obj, obj, old_hdr->size * sizeof(uint64_t));
  }

  old_hdr->color = COLOR_MARKED;

  // printf("[GC COPY] old_obj=%p -> new_obj=%p size=%u words tag=%d\n",
  //  (void *)obj, (void *)new_obj, old_hdr->size, old_hdr->tag);
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
    // printf("[UPDATE_PTRS] obj=%p, index=%u, field_ptr=%p\n", (void *)obj,
    // i,
    //        (void *)field_ptr);

    if (!on_heap(field_ptr, from_heap)) {
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

static void mark_and_copy(omletHeap_t *from_heap, omletHeap_t *to_heap) {
  stack_top = get_current_sp();
  if (stack_bottom == NULL || stack_top == NULL) {
    fprintf(stderr, "[GC] Stack not initialized properly\n");
    return;
  }
  // printf("stack_bottom: %p\n", (void *)stack_bottom);
  // printf("stack_top: %p\n", (void *)stack_top);
  // printf("cur_heap_ptr in mark_and_copy: %p\n", (void
  // *)cur_heap_ptr->start);

  // omletHeap_t *from_heap = (cur_heap_ptr == &heap_from) ? &heap_to :
  // &heap_from; omletHeap_t *to_heap = cur_heap_ptr;
  // printf("from_heap: %p\n to_heap: %p\n", (void *)from_heap->start,
  //        (void *)to_heap->start);

  for (uint64_t **ptr = stack_top; ptr <= stack_bottom; ptr++) {
    // printf("hello %p", *ptr);
    uint64_t *obj_ptr = *ptr;

    if (!on_heap(obj_ptr, from_heap))
      continue;
    // printf("hello %p\n", *ptr);

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
  printf("call collect()\n");
  // printf("from_heap->size %zu\n", cur_heap_ptr->size);
  printf("from_heap->offset %zu\n", cur_heap_ptr->offset);
  omletHeap_t *from_heap = cur_heap_ptr;
  omletHeap_t *to_heap = (cur_heap_ptr == &heap_from) ? &heap_to : &heap_from;
  to_heap->offset = 0;
  cur_heap_ptr = to_heap;

  mark_and_copy(from_heap, to_heap);
  printf("end\n");
}

// call when a single collect() didn't free enough space
void realloc_heap(void) {
  size_t old_size = heap_from.size;
  size_t new_size = old_size * 2;

  omletHeap_t old_from = heap_from;
  omletHeap_t old_to = heap_to;

  // a new buffer for the new "from"
  uint8_t *new_from_buf = malloc(new_size);
  if (!new_from_buf) {
    fprintf(stderr, "[GC REALLOC] malloc failed for new_from_buf (%zu bytes)\n",
            new_size);
    exit(1);
  }

  // a temporary to-heap that points to the new_from_buf
  omletHeap_t tmp_to;
  tmp_to.start = new_from_buf;
  tmp_to.size = new_size;
  tmp_to.offset = 0;

  // mark-and-copy from the old from-heap into tmp_to
  mark_and_copy(&old_from, &tmp_to);

  // tmp_to now contains all live objects, packed at its start
  size_t used = tmp_to.offset;
  fprintf(stderr,
          "[GC REALLOC] copied %zu bytes of live objects into new_from\n",
          used);

  uint8_t *new_to_buf = malloc(new_size);
  if (!new_to_buf) {
    fprintf(stderr, "[GC REALLOC] malloc failed for new_to_buf (%zu bytes)\n",
            new_size);
    free(new_from_buf);
    exit(1);
  }

  heap_from.start = new_from_buf;
  heap_from.size = new_size;
  heap_from.offset = used;

  heap_to.start = new_to_buf;
  heap_to.size = new_size;
  heap_to.offset = 0;

  cur_heap_ptr = &heap_from;

  // free(old_from.start);
  // free(old_to.start);

  fprintf(stderr, "[GC REALLOC] done. new heap_from at %p..%p (used=%zu)\n",
          (void *)heap_from.start, (void *)(heap_from.start + heap_from.size),
          heap_from.offset);
}

void *omlet_malloc(size_t size, tag_t tag) {
  // size_t size_in_words = (size + sizeof(uint64_t) - 1) / sizeof(uint64_t);
  // size_t payload_bytes = size_in_words * sizeof(uint64_t);
  // size_t total_size = sizeof(box_header_t) + payload_bytes;
  size_t size_in_words = (size + sizeof(uint64_t) - 1) / sizeof(uint64_t);
  // size_t payload_bytes = size_in_words * sizeof(uint64_t);
  // size_t total_size = sizeof(box_header_t) + payload_bytes;

  size_t total_size = sizeof(box_header_t) + size;
  // printf("total %zu\n", total);
  // printf("total_size %zu\n", total_size);

  // size_t total_size = sizeof(box_header_t) + size + sizeof(uint64_t) - 1;
  if (cur_heap_ptr->offset + total_size > cur_heap_ptr->size) {
    printf("size1 before collect %zu\n", cur_heap_ptr->offset + total_size);
    // collect(); // run GC
    realloc_heap();
    printf("size1 %zu\n", cur_heap_ptr->offset + total_size);
    if (cur_heap_ptr->offset + total_size > cur_heap_ptr->size) {
      printf("meow\n");
      // realloc_heap();
      fprintf(stderr, "Out of memory in omlet_malloc\n");
      exit(1);
    }
  }
  // printf("meow\n");
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
