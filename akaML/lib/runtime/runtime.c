#include <assert.h>
#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void print_int(long n) { printf("%ld", n); }

/* ========== Garbage Collector ========== */

#define SET_HEADER(size, tag) ((uint64_t)((size << 10u) + (tag % 256u)))
#define GET_SIZE(ptr) (*((uint64_t *)ptr - 1) >> 10)
#define GET_TAG(ptr) (*((uint64_t *)ptr - 1) & 0xFF)

int SIZE_HEAP = 200;
const uint8_t TAG_NUMBER = 0u;
const uint8_t TAG_CLOSURE = 1u;
const uint64_t IS_MARKED = 0xFF;

typedef struct {
  uint64_t words_allocated_total;
  uint64_t bank_current;
  uint64_t collections_count;
  uint64_t allocations_count;
} gc_stats;

typedef struct {
  uint64_t *start_bank_main;
  uint64_t *final_bank_main;
  uint64_t *start_bank_sub;
  uint64_t *final_bank_sub;
  uint64_t *ptr_base;
  uint64_t words_allocated_current;
  gc_stats stats;
} gc_data;

static gc_data GC = {
    .start_bank_main = NULL,
    .final_bank_main = NULL,
    .start_bank_sub = NULL,
    .final_bank_sub = NULL,
    .ptr_base = NULL,
    .words_allocated_current = 0,
    .stats = {.words_allocated_total = 0,
              .bank_current = 0,
              .collections_count = 0,
              .allocations_count = 0},
};

void init_gc(void) {
  GC.start_bank_main = malloc(SIZE_HEAP * sizeof(uint64_t));
  GC.final_bank_main = GC.start_bank_main + SIZE_HEAP;

  GC.start_bank_sub = malloc(SIZE_HEAP * sizeof(uint64_t));
  GC.final_bank_sub = GC.start_bank_sub + SIZE_HEAP;

  GC.ptr_base = GC.start_bank_main;
  GC.words_allocated_current = 0;
  GC.stats.bank_current = 0;
  GC.stats.words_allocated_total = 0;
  GC.stats.collections_count = 0;
  GC.stats.allocations_count = 0;
}

void destroy_gc(void) {
  free(GC.start_bank_main);
  free(GC.start_bank_sub);
}

typedef bool (*is_in_bank_t)(uint64_t *);
static bool is_in_bank_main(uint64_t *ptr) {
  return GC.start_bank_main <= ptr && ptr < GC.final_bank_main;
}
static bool is_in_bank_sub(uint64_t *ptr) {
  return GC.start_bank_sub <= ptr && ptr < GC.final_bank_sub;
}

#define GET_BANK_START(GC)                                                          \
  (GC.stats.bank_current == 0 ? GC.start_bank_main : GC.start_bank_sub)
#define GET_BANK_FINAL(GC)                                                          \
  (GC.stats.bank_current == 0 ? GC.final_bank_main : GC.final_bank_sub)
#define GET_IS_IN_BANK(GC)                                                          \
  (GC.stats.bank_current == 1 ? is_in_bank_main : is_in_bank_sub)

uint64_t get_heap_start(void) { return (uint64_t)GET_BANK_START(GC); }
uint64_t get_heap_final(void) { return (uint64_t)GET_BANK_FINAL(GC); }

void print_gc_status(void) {
  printf("=== GC Status ===\n");
  printf("Current allocated: %lu\n", GC.words_allocated_current);
  printf("Free        space: %ld\n", GET_BANK_FINAL(GC) - GC.ptr_base);
  printf("Heap         size: %d\n", SIZE_HEAP);
  printf("Heap         head: %p\n", (void *)GC.ptr_base);
  printf("Heap        start: %p\n", (void *)get_heap_start());
  printf("Heap        final: %p\n", (void *)get_heap_final());
  printf("Current      bank: %lu\n", GC.stats.bank_current);
  printf("Total   allocated: %lu\n", GC.stats.words_allocated_total);
  printf("GC    collections: %lu\n", GC.stats.collections_count);
  printf("GC    allocations: %lu\n", GC.stats.allocations_count);
  printf("=================\n");
}

static uint64_t *PTR_STACK = NULL;
void set_ptr_stack(uint64_t *ptr_stack) { PTR_STACK = ptr_stack; }

static uint64_t *copy_object(uint64_t *obj) {
  uint64_t size = GET_SIZE(obj);
  uint64_t tag = GET_TAG(obj);
  const uint64_t size_new = size + 1u;

  if (GC.ptr_base + size_new > GET_BANK_FINAL(GC)) {
    fprintf(stderr, "Out of memory during GC\n");
    exit(1);
  }

  *(GC.ptr_base) = SET_HEADER(size, tag);
  uint64_t *obj_sub = GC.ptr_base + 1;

  if (tag == TAG_CLOSURE) {
    for (int i = 0; i < size; i++) {
      obj_sub[i] = obj[i];
    }
  } else {
    memcpy(obj_sub, obj, size * sizeof(uint64_t));
  }

  obj = obj_sub;
  *(obj - 1) = SET_HEADER(size, IS_MARKED);

  GC.ptr_base += size_new;

  return obj_sub;
}

static void update_ptrs(uint64_t *obj) {
  uint64_t size = GET_SIZE(obj);
  uint64_t tag = GET_TAG(obj);

  const is_in_bank_t is_in_bank_cur = GET_IS_IN_BANK(GC);

  for (uint64_t i = 0; i < size; i++) {
    uint64_t *ptr_cond = (uint64_t *)obj[i];
    if (!is_in_bank_cur(ptr_cond))
      continue;

    if (GET_TAG(ptr_cond) == IS_MARKED) {
      obj[i] = (uint64_t)ptr_cond;
    } else {
      uint64_t *obj_sub = copy_object(ptr_cond);
      obj[i] = (uint64_t)obj_sub;
      update_ptrs(obj_sub);
    }
  }
}

static void mark_and_copy(void) {
  if (PTR_STACK == NULL)
    return;

  const is_in_bank_t is_in_bank_cur = GET_IS_IN_BANK(GC);

  uint64_t *bottom = PTR_STACK;
  uint64_t *top = __builtin_frame_address(0);

  for (uint64_t *ptr = top; ptr <= bottom; ptr++) {
    uint64_t *ptr_cond = ptr;

    if (is_in_bank_cur(ptr_cond) && GET_TAG(ptr_cond) != IS_MARKED) {
      uint64_t *obj_sub = copy_object(ptr_cond);
      ptr_cond = obj_sub;
      update_ptrs(obj_sub);
    }
  }
}

void collect(void) {
  GC.stats.collections_count++;

  GC.stats.bank_current = 1 - GC.stats.bank_current;
  uint64_t *bank_start = GET_BANK_START(GC);
  GC.ptr_base = bank_start;

  mark_and_copy();

  uint64_t words = GC.ptr_base - bank_start;
  GC.words_allocated_current = words;
}

uint64_t *gc_alloc(uint64_t size, uint64_t tag) {
  uint64_t *bank_final = GET_BANK_FINAL(GC);
  const uint64_t size_new = size + 1u;

  if (GC.ptr_base + size_new > bank_final) {
    collect();

    bank_final = GET_BANK_FINAL(GC);
    if (GC.ptr_base + size_new > bank_final) {
      fprintf(stderr, "Out of memory after GC\n");
      exit(1);
    }
  }
  GC.stats.allocations_count++;

  *(GC.ptr_base) = SET_HEADER(size, tag);

  uint64_t *obj = GC.ptr_base + 1;
  for (uint64_t i = 0u; i < size; i++) {
    obj[i] = 0u;
  }

  GC.ptr_base += size_new;
  GC.words_allocated_current += size_new;
  GC.stats.words_allocated_total += size_new;
  return obj;
}

/* ========== Closure ========== */

typedef struct {
  int64_t arity;
  int64_t args_received;
  void *code;
  void *args[];
} closure;

closure *alloc_closure(void *func, int64_t arity) {
  // init_gc();
  // print_gc_status();
  size_t size_in_bytes = sizeof(closure) + arity * sizeof(void *);
  uint64_t size_in_words =
      ((uint64_t)size_in_bytes + sizeof(uint64_t) - 1) / sizeof(uint64_t);

  closure *clos;
#ifdef ENABLE_GC
  clos = (closure *)gc_alloc(size_in_words, TAG_CLOSURE);
#endif
  clos = malloc(size_in_bytes);
  if (!clos) {
    fprintf(stderr, "Closure allocation error\n");
    exit(1);
  }

  clos->arity = arity;
  clos->args_received = 0;
  clos->code = func;
  memset(clos->args, 0, arity * sizeof(void *));

  return clos;
}

closure *copy_closure(const closure *src) {
  size_t size = sizeof(closure) + src->arity * sizeof(void *);

  closure *dst = malloc(size);
  if (!dst) {
    fprintf(stderr, "Closure allocation error\n");
    exit(1);
  }

  memcpy(dst, src, size);
  return dst;
}

void *applyN(closure *f, int64_t argc, ...) {
  closure *f_closure = (closure *)f;
  assert(argc >= 0);
  assert(f_closure->args_received + argc <= f_closure->arity);

  va_list argp;
  va_start(argp, argc);

  int64_t n = f_closure->arity;
  void **args_all = malloc(n * sizeof(void *));

  for (int64_t i = 0; i < f_closure->args_received; i++)
    args_all[i] = f_closure->args[i];

  for (int64_t i = 0; i < argc; i++)
    args_all[f_closure->args_received + i] = va_arg(argp, void *);

  va_end(argp);

  if (f_closure->args_received + argc == n) {
    void *ret;

    int64_t stack_count = (n > 8) ? (n - 8) : 0;

    size_t stack_bytes = stack_count * 8;

    void **stack_args = (stack_count > 0) ? args_all + 8 : NULL;

    asm volatile(
        /* allocate space on the stack */
        "mv   t0, %[stack_bytes]\n"
        "sub  sp, sp, t0\n"

        /* push tail arguments onto the stack (if any) */
        "mv   t1, sp\n"
        "beqz %[stack_count], en1\n"
        "mv   t2, %[stack_args]\n"
        "mv   t3, %[stack_count]\n"
        "li   t4, 0\n"
        "el1:\n"
        "beq  t4, t3, en1\n"
        "slli t5, t4, 3\n"  /* offset = i * 8 */
        "add  t6, t2, t5\n" /* addr = &stack_args[i] */
        "ld   t0, 0(t6)\n"  /* t0 = stack_args[i] */
        "sd   t0, 0(t1)\n"  /* store on stack */
        "addi t1, t1, 8\n"
        "addi t4, t4, 1\n"
        "j el1\n"
        "en1:\n"

        /* loading the first 8 arguments into registers a0..a7 */
        "mv   a0, %[a0]\n"
        "mv   a1, %[a1]\n"
        "mv   a2, %[a2]\n"
        "mv   a3, %[a3]\n"
        "mv   a4, %[a4]\n"
        "mv   a5, %[a5]\n"
        "mv   a6, %[a6]\n"
        "mv   a7, %[a7]\n"

        /* load the function address into the register and call it via jalr */
        "mv   t6, %[fn]\n"
        "jalr ra, t6, 0\n"

        /* restore the stack */
        "mv   t0, %[stack_bytes]\n"
        "add  sp, sp, t0\n"

        /* return the result to a variable */
        "mv   %[ret], a0\n"

        : [ret] "=r"(ret)
        : [fn] "r"(f_closure->code), [a0] "r"(args_all[0]), [a1] "r"(args_all[1]),
          [a2] "r"(args_all[2]), [a3] "r"(args_all[3]), [a4] "r"(args_all[4]),
          [a5] "r"(args_all[5]), [a6] "r"(args_all[6]), [a7] "r"(args_all[7]),
          [stack_args] "r"(stack_args), [stack_count] "r"(stack_count),
          [stack_bytes] "r"(stack_bytes)
        : "t0", "t1", "t2", "t3", "t4", "t5", "t6", "a0", "a1", "a2", "a3", "a4",
          "a5", "a6", "a7", "memory");

    return ret;
  }

  closure *new_closure = copy_closure(f_closure);
  for (int64_t i = 0; i < argc; i++)
    new_closure->args[new_closure->args_received++] =
        args_all[f_closure->args_received + i];

  return new_closure;
}

// Temp Main

// void a_number(void) {
//   uint64_t *local_obj = gc_alloc(1, TAG_NUMBER);
//   local_obj[0] = 100;
// }

// void a_closure(void) {
//   closure *clos =
//       (closure *)gc_alloc(sizeof(closure) / sizeof(uint64_t), TAG_CLOSURE);
//   int64_t arity = 3;
//   clos->arity = arity;
//   clos->args_received = (int64_t)2;
//   clos->code = (void *)0;
//   memset(clos->args, 0, arity * sizeof(void *));
// }

// int main() {
//   init_gc();
//   set_ptr_stack(__builtin_frame_address(0));

//   a_number();
//   for (int i = 0; i < 8; i++)
//     a_closure();
//   print_gc_status();

//   collect();
//   print_gc_status();

//   destroy_gc();
//   return 0;
// }
