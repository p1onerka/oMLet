Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ ../build_and_run.sh tuple1.ml || true
  2
  $ ../build_and_run.sh tuple1.ml --gc || true
  2
  $ ../build_and_run.sh tuple1.ml --gc 10000 || true
  2
