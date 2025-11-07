#include "gc.h"
#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  T_CLOSURE = 0,
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
  box_header_t header;
  int64_t values[];
} box_t;

box_t *create_box(tag_t tag, size_t size) {
  if (size % 8 != 0)
    size += 8 - (size % 8);

  box_t *res_box = (box_t *)omlet_malloc(sizeof(box_header_t) + size);
  res_box->header.tag = tag;
  res_box->header.color = COLOR_UNMARKED;
  res_box->header.size = size / 8;
  return res_box;
}
