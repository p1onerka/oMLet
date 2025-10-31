(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Anf

val lambda_arity_of_aexpr : aexpr -> int * aexpr
val is_function : aexpr -> bool
val analyze_aconstr : int -> aconstruction -> int
val analyze_astatement : int -> 'a * aexpr -> int
val analyze_aexpr : int -> aexpr -> int
