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
  Current allocated: 26
  Free        space: 174
  Heap         size: 200
  Current      bank: 0
  Total   allocated: 26
  GC    collections: 0
  GC    allocations: 4
  =================
  === GC Status ===
  Current allocated: 0
  Free        space: 200
  Heap         size: 200
  Current      bank: 1
  Total   allocated: 26
  GC    collections: 1
  GC    allocations: 4
  =================
  72024=== GC Status ===
  Current allocated: 40
  Free        space: 160
  Heap         size: 200
  Current      bank: 1
  Total   allocated: 66
  GC    collections: 1
  GC    allocations: 10
  =================
