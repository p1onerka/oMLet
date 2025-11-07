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
  tag_t tag;
  color_t color;
  uint16_t size;
  uint32_t pad; // alignment
} box_header_t;

typedef struct {
  box_header_t header;
  int64_t values[];
} box_t;
box_t *create_box(tag_t tag, size_t size);