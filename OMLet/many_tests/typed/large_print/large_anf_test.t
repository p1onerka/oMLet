Copyright 2025, Ksenia Kotelnikova, Sofya Kozyreva, Vyacheslav Kochergin
SPDX-License-Identifier: LGPL-3.0-or-later

  $ dune exec ../../../repl/repl.exe -- -dumpanf -fromfile large_print.ml
  let large =
  fun x -> 
    let neq_3 = 0 <> x in
      if neq_3
        then let res_of_app_1 = print_int 0 in
               res_of_app_1
        else let res_of_app_2 = print_int 1 in
               res_of_app_2
  let main =
  let eq_8 = 0 = 1 in
    if eq_8
      then let eq_6 = 0 = 1 in
             if eq_6
               then let eq_5 = 0 = 1 in
                      if eq_5
                        then let x = 0 in
                               let res_of_app_4 = large x in
                                 res_of_app_4
                        else let x = 1 in
                               let res_of_app_4 = large x in
                                 res_of_app_4
               else let eq_5 = 1 = 1 in
                      if eq_5
                        then let x = 0 in
                               let res_of_app_4 = large x in
                                 res_of_app_4
                        else let x = 1 in
                               let res_of_app_4 = large x in
                                 res_of_app_4
      else let res_of_app_7 = print_int 42 in
             let t42 = res_of_app_7 in
               let eq_6 = 1 = 1 in
                 if eq_6
                   then let eq_5 = 0 = 1 in
                          if eq_5
                            then let x = 0 in
                                   let res_of_app_4 = large x in
                                     res_of_app_4
                            else let x = 1 in
                                   let res_of_app_4 = large x in
                                     res_of_app_4
                   else let eq_5 = 1 = 1 in
                          if eq_5
                            then let x = 0 in
                                   let res_of_app_4 = large x in
                                     res_of_app_4
                            else let x = 1 in
                                   let res_of_app_4 = large x in
                                     res_of_app_4
