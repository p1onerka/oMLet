#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void *callf(void *code, uint64_t argc, void **argv);

typedef struct {
  void *code;       // function pointer
  int64_t arity;    // total number of arguments
  int64_t received; // how many arguments are already applied
  void *args[];     // flexible array of applied arguments
} closure;

// allocate a new closure
closure *alloc_closure(void *code, int64_t arity) {
  closure *c = malloc(sizeof(closure) + sizeof(void *) * arity);
  c->code = code;
  c->arity = arity;
  c->received = 0;
  memset(c->args, 0, sizeof(void *) * arity);

  // printf("[alloc_closure] code=%p arity=%ld closure=%p\n",
  //        code, arity, (void *)c);

  return c;
}

// apply arguments to a closure
void *apply(closure *f, int64_t arity, void **args, int64_t argc) {
  // printf("[apply] closure=%p arity=%ld received=%ld argc=%ld\n",
  //       (void *)f, f->arity, f->received, argc);

  int64_t total = f->received + argc;

  // full application
  if (total == f->arity) {
    void **all_args = malloc(sizeof(void *) * f->arity);

    for (int i = 0; i < f->received; i++)
      all_args[i] = f->args[i];

    for (int i = 0; i < argc; i++)
      all_args[f->received + i] = args[i];

    // printf("[apply] full application, calling function %p with %ld args\n",
    //       f->code, f->arity);

    void *result = callf(f->code, f->arity, all_args);

    free(all_args);
    return result;
  }

  // partial application : create new closure
  closure *partial = malloc(sizeof(closure) + sizeof(void *) * f->arity);
  partial->code = f->code;
  partial->arity = f->arity;
  partial->received = total;
  for (int i = 0; i < f->received; i++)
    partial->args[i] = f->args[i];
  for (int i = 0; i < argc; i++)
    partial->args[f->received + i] = args[i];

  // printf("[apply] partial application: new closure=%p total_received=%ld\n",
  //        (void *)partial, total);

  return partial;
}

void print_int(int a) {
  // printf("[print_int] %ld\n", n);
  int res = a >> 1;
  printf("%d", res);
  fflush(stdout);
}
