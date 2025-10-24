Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ dune exec ../../../repl/repl.exe -- -dumpanf -fromfile fib_print.ml
  let rec fib =
  fun n -> 
    let lt_6 = n < 2 in
      if lt_6
        then n
        else let res_of_minus_2 = n - 1 in
              let res_of_app_3 = fib res_of_minus_2 in
                let res_of_minus_4 = n - 2 in
                  let res_of_app_5 = fib res_of_minus_4 in
                    let res_of_plus_1 = res_of_app_3 + res_of_app_5 in
                      res_of_plus_1
  let main =
  let res_of_app_7 = fib 4 in
    let res_of_app_8 = print_int res_of_app_7 in
      res_of_app_8
