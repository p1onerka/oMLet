(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

let is_keyword = function
  | "if"
  | "then"
  | "else"
  | "let"
  | "in"
  | "not"
  | "true"
  | "false"
  | "fun"
  | "match"
  | "with"
  | "and"
  | "Some"
  | "None"
  | "function"
  | "->"
  | "|"
  | ":"
  | "::"
  | "_" -> true
  | _ -> false
;;
