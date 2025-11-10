#include "gc.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void *callf(void *code, uint64_t argc, void **argv);

// extern void *omlet_malloc(size_t size);
// typedef struct tag_t tag_t; // create alias
// typedef struct box_t box_t; // create alias
// extern box_t *create_box_t(tag_t tag, size_t size);

typedef struct {
  void *code;       // function pointer
  int64_t arity;    // total number of arguments
  int64_t received; // how many arguments are already applied
  void *args[];     // flexible array of applied arguments
} closure;

void print_closure(closure *c) {
  if (!c) {
    printf("<closure: NULL>\n");
    return;
  }

  printf("Closure at %p:\n", (void *)c);
  printf("  code     = %p\n", c->code);
  printf("  arity    = %ld\n", c->arity);
  printf("  received = %ld\n", c->received);

  // Print all applied arguments
  for (int64_t i = 0; i < c->received; i++) {
    printf("  args[%ld] = %p\n", i, c->args[i]);
  }
  printf("----------------------------------------\n");
}

// allocate a new closure
closure *alloc_closure(void *code, int64_t arity) {
  // printf("i want to alloc %d bytes from closure alloc\n", sizeof(closure) +
  // sizeof(void *) * arity);
  // box_t *closure_box =
  //     create_box(T_CLOSURE, sizeof(closure) + sizeof(void *) * arity);
  closure *c =
      omlet_malloc(sizeof(closure) + sizeof(void *) * arity, T_CLOSURE);
  // closure *c = (closure *)&closure_box->values;
  c->code = code;
  c->arity = arity;
  c->received = 0;
  memset(c->args, 0, sizeof(void *) * arity);

  // printf("[alloc_closure] code=%p arity=%ld closure=%p\n",
  //        code, arity, (void *)c);

  // printf("alloc closure\n");
  // print_closure(c);
  // closure *tagged_c = (closure *)((uintptr_t)c << 1);
  // return tagged_c;
  return c;
}

// apply arguments to a closure
void *apply(closure *tagged_f, int64_t arity, void **args, int64_t argc) {
  // printf("[apply] closure=%p arity=%ld received=%ld argc=%ld\n",
  //       (void *)f, f->arity, f->received, argc);

  // closure *f = (closure *)((uintptr_t)tagged_f >> 1);
  closure *f = tagged_f;
  // printf("apply closure\n");
  // print_closure(f);

  int64_t total = f->received + argc;

  // full application
  if (total == f->arity) {
    // printf("i want to alloc %d bytes from full\n", sizeof(void *) *
    // f->arity);
    void **all_args = omlet_malloc(sizeof(void *) * f->arity, T_UNBOXED);

    for (int i = 0; i < f->received; i++)
      all_args[i] = f->args[i];
    for (int i = 0; i < argc; i++)
      all_args[f->received + i] = args[i];

    // printf("[apply] full application, calling function %p with %ld args\n",
    //       f->code, f->arity);

    // printf("supposedly allocated\n");
    void *result = callf(f->code, f->arity, all_args);
    // printf("boom\n");

    return result;
  }

  // printf("partial application : f before malloc\n");
  // print_closure(f);
  closure *partial =
      omlet_malloc(sizeof(closure) + sizeof(void *) * f->arity, T_CLOSURE);
  // printf("partial application : f after malloc\n");
  // print_closure(f);
  // printf("partial application : create new closure\n");

  partial->code = f->code;
  partial->arity = f->arity;
  partial->received = total;

  for (int i = 0; i < f->received; i++) {
    // printf("I GOT %d ARG\n", i);
    partial->args[i] = f->args[i];
  }
  for (int i = 0; i < argc; i++)
    partial->args[f->received + i] = args[i];

  // print_closure(partial);
  // printf("[apply] partial application: new closure=%p total_received=%ld\n",
  //        (void *)partial, total);

  // closure *tagged_partial = (closure *)((uintptr_t)partial << 1);

  // return tagged_partial;
  return partial;
}

void print_int(int64_t a) {
  // printf("[print_int] %ld\n", n);
  int64_t res = a >> 1;
  printf("%ld", res);
  fflush(stdout);
}
