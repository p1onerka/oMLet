#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HEAP_INIT_SIZE 100

typedef struct {
    uint8_t* start;
    size_t size;
    size_t offset;
} omletHeap;

int init_heap(omletHeap* heap, size_t size) {
    heap->start = (uint8_t*) malloc(size);
    heap->size = size;
    heap->offset = 0;
    return 1;
}

void* omlet_malloc(omletHeap* heap, size_t size) {
    if (heap->offset + size > heap->size) {
        printf("there will be realloc");
        return NULL;
    }
    void* free_ptr = heap->start + heap->offset;
    heap->offset += size;
    return free_ptr;
}

