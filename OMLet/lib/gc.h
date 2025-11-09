#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  T_UNBOXED = 0,
  T_CLOSURE = 1,
} tag_t;

void *omlet_malloc(size_t size, tag_t tag);
