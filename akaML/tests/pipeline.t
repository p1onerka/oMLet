Copyright 2025-2026, Friend-zva, RodionovMaxim05
SPDX-License-Identifier: LGPL-3.0-or-later

====================== without gc ======================
  $ ../bin/akaML.exe -fromfile manytests/typed/001fac.ml -o 001fac.s
  $ riscv64-linux-gnu-as -march=rv64gc 001fac.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  24

  $ ../bin/akaML.exe -fromfile manytests/typed/004manyargs.ml -o 004manyargs.s
  $ riscv64-linux-gnu-as -march=rv64gc 004manyargs.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  1111111111110100

  $ ../bin/akaML.exe -fromfile manytests/typed/010faccps_ll.ml -o 010faccps_ll.s
  $ riscv64-linux-gnu-as -march=rv64gc 010faccps_ll.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  24

  $ ../bin/akaML.exe -fromfile manytests/typed/010fibcps_ll.ml -o 010fibcps_ll.s
  $ riscv64-linux-gnu-as -march=rv64gc 010fibcps_ll.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  8

  $ ../bin/akaML.exe -fromfile manytests/typed/012faccps.ml -o 012faccps.s
  $ riscv64-linux-gnu-as -march=rv64gc 012faccps.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  720

  $ ../bin/akaML.exe -fromfile manytests/typed/012fibcps.ml -o 012fibcps.s
  $ riscv64-linux-gnu-as -march=rv64gc 012fibcps.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  8

====================== gc ======================
  $ ../bin/akaML.exe -gc -fromfile manytests/typed/001fac.ml -o 001fac.s
  $ riscv64-linux-gnu-as -march=rv64gc 001fac.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  24

  $ ../bin/akaML.exe -gc -fromfile manytests/typed/004manyargs.ml -o 004manyargs.s
  $ riscv64-linux-gnu-as -march=rv64gc 004manyargs.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  1111111111110100

  $ ../bin/akaML.exe -gc -fromfile manytests/typed/010faccps_ll.ml -o 010faccps_ll.s
  $ riscv64-linux-gnu-as -march=rv64gc 010faccps_ll.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  24

  $ ../bin/akaML.exe -gc -fromfile manytests/typed/010fibcps_ll.ml -o 010fibcps_ll.s
  $ riscv64-linux-gnu-as -march=rv64gc 010fibcps_ll.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  8

  $ ../bin/akaML.exe -gc -fromfile manytests/typed/012faccps.ml -o 012faccps.s
  $ riscv64-linux-gnu-as -march=rv64gc 012faccps.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  720

  $ ../bin/akaML.exe -gc -fromfile manytests/typed/012fibcps.ml -o 012fibcps.s
  $ riscv64-linux-gnu-as -march=rv64gc 012fibcps.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  8

  $ ../bin/akaML.exe -gc -fromfile fewtests/01faccps.ml -o 01faccps.s
  $ riscv64-linux-gnu-as -march=rv64gc 01faccps.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  === GC Status ===
  Current allocated: 73
  Free        space: 1427
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 73
  GC    collections: 0
  GC    allocations: 14
  =================
  === GC Status ===
  Current allocated: 5
  Free        space: 1495
  Heap         size: 1500
  Current      bank: 1
  Total   allocated: 73
  GC    collections: 1
  GC    allocations: 14
  =================
  72024=== GC Status ===
  Current allocated: 122
  Free        space: 1378
  Heap         size: 1500
  Current      bank: 1
  Total   allocated: 190
  GC    collections: 1
  GC    allocations: 36
  =================

  $ ../bin/akaML.exe -gc -fromfile fewtests/02facclos.ml -o 02facclos.s
  $ riscv64-linux-gnu-as -march=rv64gc 02facclos.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  === GC Status ===
  Current allocated: 6
  Free        space: 1494
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 6
  GC    collections: 0
  GC    allocations: 1
  =================
  === GC Status ===
  Current allocated: 6
  Free        space: 1494
  Heap         size: 1500
  Current      bank: 1
  Total   allocated: 6
  GC    collections: 1
  GC    allocations: 1
  =================
  48=== GC Status ===
  Current allocated: 11
  Free        space: 1489
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 16
  GC    collections: 2
  GC    allocations: 4
  =================

  $ ../bin/akaML.exe -gc -fromfile fewtests/03clos.ml -o 03clos.s
  $ riscv64-linux-gnu-as -march=rv64gc 03clos.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  === GC Status ===
  Current allocated: 7
  Free        space: 1493
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 7
  GC    collections: 0
  GC    allocations: 1
  =================
  === GC Status ===
  Current allocated: 7
  Free        space: 1493
  Heap         size: 1500
  Current      bank: 1
  Total   allocated: 7
  GC    collections: 1
  GC    allocations: 1
  =================
  === GC Status ===
  Current allocated: 7
  Free        space: 1493
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 11
  GC    collections: 2
  GC    allocations: 2
  =================

  $ ../bin/akaML.exe -gc -fromfile fewtests/04clos.ml -o 04clos.s
  $ riscv64-linux-gnu-as -march=rv64gc 04clos.s -o temp.o
  $ riscv64-linux-gnu-gcc temp.o ../lib/runtime/rv64_gc_runtime.a -o file.exe
  $ qemu-riscv64 -L /usr/riscv64-linux-gnu -cpu rv64 ./file.exe
  === GC Status ===
  Current allocated: 24
  Free        space: 1476
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 24
  GC    collections: 0
  GC    allocations: 3
  =================
  === GC Status ===
  Current allocated: 39
  Free        space: 1461
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 39
  GC    collections: 0
  GC    allocations: 5
  =================
  === GC Status ===
  Current allocated: 18
  Free        space: 1482
  Heap         size: 1500
  Current      bank: 1
  Total   allocated: 39
  GC    collections: 1
  GC    allocations: 5
  =================
  === GC Status ===
  Current allocated: 18
  Free        space: 1482
  Heap         size: 1500
  Current      bank: 0
  Total   allocated: 45
  GC    collections: 2
  GC    allocations: 6
  =================
  15
