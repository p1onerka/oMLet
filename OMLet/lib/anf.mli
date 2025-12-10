(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Ast

type immexpr =
  | ImmNum of int
  | ImmId of ident
  | ITuple of immexpr * immexpr * immexpr list
[@@deriving show { with_path = false }]

type cbinop =
  | CPlus
  | CMinus
  | CMul
  | CDiv
  | CEq
  | CNeq
  | CLt
  | CLte
  | CGt
  | CGte
[@@deriving show { with_path = false }]

type cexpr =
  | CBinop of cbinop * immexpr * immexpr
  | CIte of cexpr * aexpr * aexpr option
  | CImmexpr of immexpr
  | CLam of ident * aexpr
  | CApp of immexpr * immexpr list
  | CField of immexpr * int
[@@deriving show { with_path = false }]

and aexpr =
  | ALet of ident * cexpr * aexpr
  | ACExpr of cexpr
[@@deriving show { with_path = false }]

type aconstruction =
  | AExpr of aexpr
  | AStatement of is_recursive * (ident * aexpr) list
[@@deriving show { with_path = false }]

type aconstructions = aconstruction list [@@deriving show { with_path = false }]

type anf_error =
  | Unreachable
  | Not_Yet_Implemented of string
[@@deriving show { with_path = false }]

open ResultCounter

val gen_temp : string -> (ident, 'a) ResultCounterMonad.t

val anf_and_lift_program
  :  construction list
  -> (aconstruction list, anf_error) ResultCounterMonad.t

val pp_anf_error : Format.formatter -> anf_error -> unit
