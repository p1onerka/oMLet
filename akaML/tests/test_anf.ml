[@@@ocaml.text "/*"]

(** Copyright 2025-2026, Friend-zva, RodionovMaxim05 *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

[@@@ocaml.text "/*"]

open Middleend
open Parser

let run str =
  match parse str with
  | Ok ast ->
    (match Anf_core.anf_structure ast with
     | Error e_anf -> Format.eprintf "ANF transformation error: %s\n%!" e_anf
     | Ok anf_ast -> Format.printf "%a" Anf_pprinter.pp_a_structure anf_ast)
  | Error error -> Format.printf "%s" error
;;

let%expect_test "ANF constant" =
  run
    {|
  let a = 1;;
  |};
  [%expect
    {|
  let a = 1;;
  |}]
;;

let%expect_test "ANF Pat_any" =
  run
    {|
  let a =
    let _ = 3 in
    0
  ;;
  |};
  [%expect
    {|
  let a = 0;;
  |}]
;;

let%expect_test "ANF binary operation" =
  run
    {|
  let a = 1 + 2;;
  |};
  [%expect
    {|
  let a = 1 + 2;;
  |}]
;;

let%expect_test "ANF several binary operations" =
  run
    {|
  let a = 1 + 2 + 3;;
  |};
  [%expect
    {|
  let a = let temp0 = 1 + 2 in
          temp0 + 3;;
  |}]
;;

let%expect_test "ANF function with 1 argument" =
  run
    {|
  let f a = a;;
  let a = f 1;;
  |};
  [%expect
    {|
  let f = fun a -> a;;
  let a = f 1;;
  |}]
;;

let%expect_test "ANF ifthen" =
  run
    {|
  let foo n = if n < -5 then print_int 0
  |};
  [%expect
    {|
  let foo =
    fun n ->
      (let temp0 = -5 in
      let temp1 = n < temp0 in
      if temp1 then print_int 0);;
  |}]
;;

let%expect_test "ANF tuple" =
  run
    {|
  let tup a = 1, a
  |};
  [%expect
    {|
  let tup = fun a -> ( 1, a );;
  |}]
;;

let%expect_test "ANF tuple pattern" =
  run
    {|
  let f a (b, c) = a (b, c);;
  |};
  [%expect
    {|
  let f =
    fun a ->
      (fun temp3 ->
         (let b = field temp3 0 in
         let c = field temp3 1 in
         let temp0 = b, c in
         a temp0));;
  |}]
;;

let%expect_test "ANF nested tuple pattern" =
  run
    {|
  let f a (b, (c, (d, e)), f) = a (b, c);;
  let a = g (1, (2, 3), 4);;
  |};
  [%expect
    {|
  let f =
    fun a ->
      (fun temp3 ->
         (let b = field temp3 0 in
         let temp4 = field temp3 1 in
         let c = field temp4 0 in
         let temp5 = field temp4 1 in
         let d = field temp5 0 in
         let e = field temp5 1 in
         let f = field temp3 2 in
         let temp0 = b, c in
         a temp0));;
  let a = let temp6 = 2, 3 in
          let temp7 = 1, temp6, 4 in
          g temp7;;
  |}]
;;

let%expect_test "ANF tuple pattern with numbers" =
  run
    {|
  let f a (1, 2) = a (1 + 2);;
  |};
  [%expect
    {|
  let f =
    fun a ->
      (fun temp3 ->
         (let 1 = field temp3 0 in
         let 2 = field temp3 1 in
         let temp0 = 1 + 2 in
         a temp0));;
  |}]
;;

let%expect_test "ANF tuple as left value" =
  run
    {|
  let (a, b) = (1, 2);;
  let f =
    let (c, d) = (3, 4) in
    (c, d)
  ;;
  |};
  [%expect
    {|
  let temp1 = 1, 2;;
  let a = field temp1 0;;
  let b = field temp1 1;;
  let f =
    let temp4 = 3, 4 in
    let c = field temp4 0 in
    let d = field temp4 1 in
    c, d;;
  |}]
;;

let%expect_test "ANF nested tuple as left value" =
  run
    {|
  let f = 1, (2, (3, 4)), 5;;
  let a, (b, (c, d)), e = 1, (2, (3, 4)), 5;;
  |};
  [%expect
    {|
  let f = let temp0 = 3, 4 in
          let temp1 = 2, temp0 in
          1, temp1, 5;;
  let temp3 = 3, 4;;
  let temp4 = 2, temp3;;
  let temp6 = 1, temp4, 5;;
  let a = field temp6 0;;
  let temp7 = field temp6 1;;
  let b = field temp7 0;;
  let temp8 = field temp7 1;;
  let c = field temp8 0;;
  let d = field temp8 1;;
  let e = field temp6 2;;
  |}]
;;

let%expect_test "ANF function with 2 arguments" =
  run
    {|
  let f a b = a + b;;
  let a = f 1 2;;
  |};
  [%expect
    {|
  let f = fun a -> (fun b -> a + b);;
  let a = f 1 2;;
  |}]
;;

let%expect_test "ANF factorial" =
  run
    {|
  let rec fac n = if n = 0 then 1 else n * fac (n - 1);;
  |};
  [%expect
    {|
  let rec fac =
    fun n ->
      (let temp0 = n = 0 in
      if temp0 then 1
      else (let temp1 = n - 1 in
        let temp2 = fac temp1 in
        n * temp2));;
  |}]
;;

let%expect_test "ANF fibonacci" =
  run
    {|
  let rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2);;
  |};
  [%expect
    {|
  let rec fib =
    fun n ->
      (let temp0 = n < 2 in
      if temp0 then n
      else (let temp1 = n - 1 in
        let temp2 = fib temp1 in
        let temp3 = n - 2 in
        let temp4 = fib temp3 in
        temp2 + temp4));;
  |}]
;;

let%expect_test "Check elimination: let name = value in name -> value" =
  run
    {|
  let foo =
    let x = 1 in
    let y = 2 in
    x + y
  ;;
  |};
  [%expect
    {|
  let foo = let x = 1 in
            let y = 2 in
            x + y;;
  |}]
;;

let%expect_test
    "Check elimination: let name = value in let orig_name = name in body -> let \
     orig_name = value in body"
  =
  run
    {|
  let foo =
    let a = 1 + 2 in
    let b = 3 - 4 in
    let c = 5 * 6 in
    let d = 7 <= 8 in
    let e = 9 >= 10 in
    let f = 11 = 12 in
    let g = 13 <> 14 in
    a
  ;;
  |};
  [%expect
    {|
  let foo =
    let a = 1 + 2 in
    let b = 3 - 4 in
    let c = 5 * 6 in
    let d = 7 <= 8 in
    let e = 9 >= 10 in
    let f = 11 = 12 in
    let g = 13 <> 14 in
    a;;
  |}]
;;
