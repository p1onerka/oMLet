(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Anf
open Ast

let rec lambda_arity_of_aexpr ae =
  match ae with
  | ACExpr (CLam (_, inner)) ->
    let sub_arity, body = lambda_arity_of_aexpr inner in
    1 + sub_arity, body
  | ACExpr _ -> 0, ae
  | ALet _ -> 0, ae
;;

let is_function = function
  | ACExpr (CLam (Ident _, _)) -> true
  | _ -> false
;;

(* if argument is const, it will be put on stack. else it is already on it *)
let analyze_arg stack_size = function
  | ImmNum _ -> stack_size + 1
  | _ -> stack_size
;;

let rec analyze_cexpr stack_size = function
  | CBinop (_, _, _) -> stack_size
  | CImmexpr _ -> stack_size
  | CIte (cond, thn, els) ->
    let stack_size = analyze_cexpr stack_size cond in
    let stack_size = analyze_aexpr stack_size thn in
    (match els with
     | None -> stack_size
     | Some els -> analyze_aexpr stack_size els)
  | CLam (Ident _, ae) -> analyze_aexpr (stack_size + 1) ae
  | CApp (_, args) ->
    (* uncomment that if t-regs will be used again *)
    (* stack_size (*+ 7*) + List.length args *)
    List.fold_left analyze_arg stack_size args
  | CField (_, _) -> stack_size

and analyze_aexpr stack_size = function
  | ACExpr ce -> analyze_cexpr stack_size ce
  | ALet (_, cexpr, body) ->
    let stack_size = analyze_cexpr stack_size cexpr in
    let stack_size = analyze_aexpr stack_size body in
    stack_size + 1
;;

let analyze_astatement stack_size = function
  | _, st when is_function st ->
    (* + 1 for RA *)
    analyze_aexpr (stack_size + 1) st
  | _, st -> analyze_aexpr stack_size st
;;

let analyze_aconstr stack_size = function
  | AExpr ae -> analyze_aexpr stack_size ae
  | AStatement (_, st_list) -> List.fold_left analyze_astatement stack_size st_list
;;
