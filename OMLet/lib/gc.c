#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HEAP_INIT_SIZE 1000

typedef struct {
    uint8_t* start;
    size_t size;
    size_t offset;
} omletHeap_t;

omletHeap_t cur_heap;
omletHeap_t* cur_heap_ptr = &cur_heap;

void init_heap(size_t size) {
    cur_heap_ptr->start = (uint8_t*) malloc(size);
    cur_heap_ptr->size = size;
    cur_heap_ptr->offset = 0;
}

void init_start_heap() {
    init_heap(HEAP_INIT_SIZE);
}

void free_heap() {
    free(cur_heap_ptr->start);
}

uintptr_t get_heap_start() {
    return ((uintptr_t)cur_heap_ptr->start << 1) + 1;
}

uintptr_t get_heap_fin() {
    return ((uintptr_t)(cur_heap_ptr->start + cur_heap_ptr->size) << 1) + 1;
}

size_t get_heap_free_size() {
    return ((cur_heap_ptr->size - cur_heap_ptr->offset) << 1) + 1;
}

void *omlet_malloc(size_t size) {
    if (cur_heap_ptr->offset + size > cur_heap_ptr->size) {
        printf("there will be realloc");
        return NULL;
    }
    void* free_ptr = cur_heap_ptr->start + cur_heap_ptr->offset;
    cur_heap_ptr->offset += size;
    //printf("I ALLOCATED %d NOW FREE SIZE IS %d AND OFFSET IS %d\n", size, (get_heap_free_size() >> 1), cur_heap_ptr->offset);
    return free_ptr;
}

