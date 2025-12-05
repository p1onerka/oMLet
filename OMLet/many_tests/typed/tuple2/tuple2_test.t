Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ ../build_and_run.sh tuple2.ml || true
  55
  $ ../build_and_run.sh tuple2.ml --gc || true
  55
  $ ../build_and_run.sh tuple2.ml --gc 10000 || true
  55
