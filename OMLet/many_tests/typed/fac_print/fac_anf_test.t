Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ dune exec ../../../repl/repl.exe -- -dumpanf -fromfile fac_print.ml
  let rec fac =
  fun n -> 
    let lte_4 = n <= 1 in
      if lte_4
        then 1
        else let res_of_minus_2 = n - 1 in
              let res_of_app_3 = fac res_of_minus_2 in
                let res_of_mul_1 = n * res_of_app_3 in
                  res_of_mul_1
  let main =
  let res_of_app_5 = fac 4 in
    let res_of_app_6 = print_int res_of_app_5 in
      res_of_app_6