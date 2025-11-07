#include "boxing.h"
#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HEAP_INIT_SIZE 1000

typedef struct {
  uint8_t *start;
  size_t size;
  size_t offset;
} omletHeap_t;

omletHeap_t cur_heap;
omletHeap_t *cur_heap_ptr = &cur_heap;

omletHeap_t *alloc_heap(size_t size) {
  uint8_t *start = (uint8_t *)malloc(size);
  omletHeap_t *heap_ptr = (omletHeap_t *)malloc(sizeof(*heap_ptr));
  heap_ptr->start = start;
  heap_ptr->size = size;
  heap_ptr->offset = 0;
  return heap_ptr;
}

void init_heap(size_t size) { cur_heap_ptr = alloc_heap(size); }

// void *get_current_sp() {
//   void *ret;
//   asm volatile("mv a0, sp\n" : [ret] "=r"(ret));
//   return ret;
// }

static inline void *get_current_sp(void) {
  printf("help\n");
  void *sp_val;
  printf("sp_val1: %p\n", (void *)sp_val);
  asm volatile("mv %0, sp" : "=r"(sp_val));
  printf("sp_val2: %p\n", (void *)sp_val);
  return sp_val;
}

box_t **stack_bottom = NULL;
box_t **stack_top;

void init_start_heap() {
  stack_bottom = get_current_sp();
  printf("Stack bottom init: %p\n", (void *)stack_bottom);
  init_heap(HEAP_INIT_SIZE);
}

// void free_heap(omletHeap_t *heap) {
//   free(heap->start);
//   free(heap);
// }

void free_heap() { free(cur_heap_ptr->start); }

uintptr_t get_heap_start() { return ((uintptr_t)cur_heap_ptr->start << 1) + 1; }

uintptr_t get_heap_fin() {
  return ((uintptr_t)(cur_heap_ptr->start + cur_heap_ptr->size) << 1) + 1;
}

size_t get_heap_free_size() {
  return ((cur_heap_ptr->size - cur_heap_ptr->offset) << 1) + 1;
}

void *malloc_on_current_heap(size_t size) {
  void *free_ptr = cur_heap_ptr->start + cur_heap_ptr->offset;
  cur_heap_ptr->offset += size;
  return free_ptr;
}

int ptr(int64_t arg) { return !(arg & 1); };

uint8_t on_heap(box_t *box, omletHeap_t *heap) {
  if (ptr((int64_t)box)) {
    uintptr_t box_addr = (uintptr_t)box;
    uintptr_t heap_start = (uintptr_t)heap->start;
    uintptr_t heap_end = heap_start + heap->size;
    return (heap_start <= box_addr) && (box_addr < heap_end);
  }
  return 0;
}

box_t *mark_and_copy(box_t *old_box, omletHeap_t *old_heap) {
  if (!on_heap(old_box, old_heap) || old_box->header.tag != T_CLOSURE) {
    printf("not on heap !\n");
    return old_box;
  }
  printf("here here 1 !\n");
  printf("heeee !\n");
  if (old_box->header.color == COLOR_MARKED) {
    printf("MARKED !\n");
    return (box_t *)old_box->values[0];
  } else {
    printf("unMARKED !\n");
    box_t *new = (box_t *)malloc_on_current_heap(sizeof(box_header_t) +
                                                 old_box->header.size * 8);

    printf("unMARKED2 !\n");
    printf("new: %p\n", (void *)new);
    printf("old_box->header: %ld\n", old_box->header.size);
    printf("new->header: %ld\n", new->header.size);
    new->header = old_box->header;
    printf("unMARKED3 !\n");
    old_box->header.color = COLOR_MARKED;
    int64_t fst_value_buf = old_box->values[0];
    old_box->values[0] = (int64_t)new; // used as a forwarding pointer
    new->values[0] = (int64_t)mark_and_copy((box_t *)fst_value_buf, old_heap);
    printf("old_box->values[0]: %ld\n", old_box->values[0]);
    for (int i = 1; i < old_box->header.size; i++) {
      printf("here here!\n");
      new->values[i] =
          (int64_t)mark_and_copy((box_t *)old_box->values[i], old_heap);
    }
    return (box_t *)((uint64_t)new);
  }
}

void realloc_heap(size_t size) {
  printf("realloc!\n");
  stack_top = get_current_sp();
  printf("Stack bottom: %p\n", (void *)stack_bottom);
  printf("Stack top: %p\n", (void *)stack_top);
  omletHeap_t *old_heap = cur_heap_ptr;
  printf("old_heap ptr: %p\n", cur_heap_ptr);

  omletHeap_t *new_heap = alloc_heap(size);
  cur_heap_ptr = new_heap;
  printf("new_heap ptr: %p\n", cur_heap_ptr);

  for (box_t **value = stack_top; value < stack_bottom; value++) {
    printf("mc!\n");
    *value = mark_and_copy(*value, old_heap);
  }

  free(old_heap->start);
  free(old_heap);
}

void *omlet_malloc(size_t size) {

  size_t sizec = cur_heap_ptr->size;
  // printf("cur_heap_ptr->size: %zu\n", sizec);
  // printf("needed size: %zu\n", cur_heap_ptr->offset + size);
  // printf("malloc\n");
  if (cur_heap_ptr->offset + size > cur_heap_ptr->size) {
    // printf("size: %zu\n", size);
    size_t cur_size = cur_heap_ptr->size;
    size_t needed_sz = size + cur_heap_ptr->offset;
    while (cur_size < needed_sz) {
      cur_size <<= 1;
    }
    printf("before realloc\n");
    realloc_heap(cur_size);
    return malloc_on_current_heap(size);
  }
  return malloc_on_current_heap(size);
}
