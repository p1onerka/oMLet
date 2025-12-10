Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ ../build_and_run.sh tuple3.ml || true
  90
  $ ../build_and_run.sh tuple3.ml --gc || true
  90
  $ ../build_and_run.sh tuple3.ml --gc 10000 || true
  90
