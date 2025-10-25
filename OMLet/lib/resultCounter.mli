(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

module type ResultCounterMonadType = sig
  type ('a, 'e) t

  val return : 'a -> ('a, 'e) t
  val ( >>= ) : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t
  val fail : 'e -> ('a, 'e) t
  val read : (int, 'e) t
  val write : int -> (unit, 'e) t
  val run : ('a, 'e) t -> int -> ('a * int, 'e) result

  module Syntax : sig
    val ( let* ) : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t
  end
end

module ResultCounterMonad : ResultCounterMonadType
