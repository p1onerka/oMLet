(** Copyright 2025, Ksenia Kotelnikova <xeniia.ka@gmail.com>, Sofya Kozyreva <k81sofia@gmail.com>, Vyacheslav Kochergin <vyacheslav.kochergin1@gmail.com> *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open Ast
open Format

type immexpr =
  | ImmNum of int (* 42 *)
  | ImmId of ident (* a *)
[@@deriving show { with_path = false }]

type cbinop =
  | CPlus (* 42 + a *)
  | CMinus (* 42 - a *)
  | CMul (* 42 * a *)
  | CDiv (* 42 / a *)
  | CEq (* 42 = a *)
  | CNeq (* 42 != a *)
  | CLt (* 42 < a *)
  | CLte (* 42 <= a *)
  | CGt (* 42 > a *)
  | CGte (* 42 >= a *)
[@@deriving show { with_path = false }]

type cexpr =
  | CBinop of cbinop * immexpr * immexpr
  | CIte of cexpr * aexpr * aexpr option (* if (42 > a) then 42 else a *)
  | CImmexpr of immexpr
  | CLam of ident * aexpr (* fun a -> a + 42 *)
  | CApp of immexpr * immexpr list (* func_name arg1 arg2 ... argn *)
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

let pp_anf_error fmt = function
  | Unreachable -> fprintf fmt "Panic: reached unreachable state in ANF computation"
  | Not_Yet_Implemented str ->
    fprintf fmt "ANF for this structure is not yet implemented: %s" str
[@@deriving show { with_path = false }]
;;

open ResultCounter.ResultCounterMonad
open Syntax

let gen_temp base =
  let* c = read in
  let new_c = c + 1 in
  let* () = write new_c in
  return (Ident (Stdlib.Format.sprintf "%s_%d" base c))
;;

let binop_map = function
  | Binary_add -> return ("res_of_plus", CPlus)
  | Binary_subtract -> return ("res_of_minus", CMinus)
  | Binary_multiply -> return ("res_of_mul", CMul)
  | Binary_divide -> return ("res_of_div", CDiv)
  | Binary_equal -> return ("eq", CEq)
  | Binary_unequal -> return ("neq", CNeq)
  | Binary_less -> return ("lt", CLt)
  | Binary_less_or_equal -> return ("lte", CLte)
  | Binary_greater -> return ("gt", CGt)
  | Binary_greater_or_equal -> return ("gte", CGte)
  | _ -> fail (Not_Yet_Implemented "binary operator")
;;

let rec collect_app_args e =
  match e with
  | Apply (f, a) ->
    let fn, args = collect_app_args f in
    fn, args @ [ a ]
  | _ -> e, []
;;

let pre_lifted_functions = ref []
let pre_lifted_letins = ref []

let rec anf e expr_with_hole =
  let anf_binop opname op left right expr_with_hole =
    let* varname = gen_temp opname in
    let* left_anf =
      anf left (fun limm ->
        let* right_anf =
          anf right (fun rimm ->
            let* inner = expr_with_hole (ImmId varname) in
            return (ALet (varname, CBinop (op, limm, rimm), inner)))
        in
        return right_anf)
    in
    return left_anf
  in
  match e with
  | Const (Int_lt n) -> expr_with_hole (ImmNum n)
  | Variable id -> expr_with_hole (ImmId id)
  | Bin_expr (op, l, r) ->
    let* opname, op_name = binop_map op in
    anf_binop opname op_name l r expr_with_hole
  | LetIn (_, Let_bind (PVar id, [], expr), [], body) ->
    let* body_anf = anf body expr_with_hole in
    anf expr (fun immval -> return (ALet (id, CImmexpr immval, body_anf)))
  | LetIn (_, Let_bind (PConst Unit_lt, [], expr), [], body) ->
    anf expr (fun _ -> anf body expr_with_hole)
  | LetIn (_, Let_bind (Wild, [], expr), [], body) ->
    anf expr (fun _ -> anf body expr_with_hole)
  | LetIn (_, Let_bind (PVar id, args, expr), [], body) ->
    let* arg_names =
      List.fold_right
        (fun pat acc ->
           let* names = acc in
           match pat with
           | PVar s -> return (s :: names)
           | _ -> fail (Not_Yet_Implemented "complex patterns"))
        args
        (return [])
    in
    let* value = anf expr (fun imm -> return (ACExpr (CImmexpr imm))) in
    let clams =
      List.fold_right (fun id body -> ACExpr (CLam (id, body))) arg_names value
    in
    let* cclams =
      match clams with
      | ACExpr c -> return c
      | _ -> fail Unreachable
    in
    let* body = anf body expr_with_hole in
    let* lifted_name = gen_temp "lifted_letin" in
    pre_lifted_letins := (id, cclams) :: !pre_lifted_letins ;
    (* return (ALet (id, cclams, body)) *)
    return body
  | If_then_else (cond, thn, Some els) ->
    let* thn = anf thn expr_with_hole in
    let* els = anf els expr_with_hole in
    anf cond (fun condimm -> return (ACExpr (CIte (CImmexpr condimm, thn, Some els))))
  | Apply (f, args) ->
    let f, arg_exprs = collect_app_args (Apply (f, args)) in
    anf f (fun fimm ->
      let rec anf_args acc = function
        | [] ->
          let* varname = gen_temp "res_of_app" in
          let* e = expr_with_hole (ImmId varname) in
          return (ALet (varname, CApp (fimm, List.rev acc), e))
        | expr :: rest -> anf expr (fun immval -> anf_args (immval :: acc) rest)
      in
      anf_args [] arg_exprs)
  | Lambda (first, rest, body) ->
    let* arg_names =
      List.fold_right
        (fun pat acc ->
           let* names = acc in
           match pat with
           | PVar s -> return (s :: names)
           | _ -> fail (Not_Yet_Implemented "complex patterns"))
        (first :: rest)
        (return [])
    in
    let* varname = gen_temp "lam" in
    Stdlib.Format.printf "body ast %a@.\n" pp_expr body;
    let* e = expr_with_hole (ImmId varname) in
    let* body = anf body (fun imm -> return (ACExpr (CImmexpr imm))) in
    Stdlib.Format.printf "body anf %a@.\n" pp_aexpr body;
    let clams =
      List.fold_right (fun id body -> ACExpr (CLam (id, body))) arg_names body
    in
    let* cclams =
      match clams with
      | ACExpr c -> return c
      | _ -> fail Unreachable
    in
    (* | ALet (varname, CLam (id, ae), body) ->
    let lifted_functions = (varname, CLam (id, ae)) :: lifted_functions in
    Stdlib.Format.printf "CLam %a@. %a\n" pp_cexpr (CLam (id, ae)) pp_ident varname;
    return (body, lifted_functions) *)
    let* lifted_name = gen_temp "lifted_lam" in
    pre_lifted_functions := (lifted_name, cclams) :: !pre_lifted_functions ;
    (* pre_lifted_functions := !pre_lifted_functions @ [ (lifted_name, cclams) ]; *)

    (* pre_lifted_functions := (varname, cclams) :: !pre_lifted_functions; *)
    (* return e *)
     return (ALet (varname, CImmexpr (ImmId lifted_name), e))
  | e ->
    Stdlib.Format.printf "%a@." pp_expr e;
    fail (Not_Yet_Implemented "ANF expr")
;;

let anf_construction = function
  | Statement (Let (flag, Let_bind (PVar id, [], expr), [])) ->
    let* value = anf expr (fun immval -> return (ACExpr (CImmexpr immval))) in
    return (AStatement (flag, [ id, value ]))
  | Statement (Let (flag, Let_bind (PVar name, args, expr), [])) ->
    let* arg_names =
      List.fold_right
        (fun pat acc ->
           let* names = acc in
           match pat with
           | PVar s -> return (s :: names)
           | _ -> fail (Not_Yet_Implemented "complex patterns"))
        args
        (return [])
    in
    let* value = anf expr (fun imm -> return (ACExpr (CImmexpr imm))) in
    let clams =
      List.fold_right (fun id body -> ACExpr (CLam (id, body))) arg_names value
    in
    return (AStatement (flag, [ name, clams ]))
  | Expr e ->
    let* inner = anf e (fun immval -> return (ACExpr (CImmexpr immval))) in
    return (AExpr inner)
  | _ -> fail (Not_Yet_Implemented "ANF construction")
;;

let rec anf_constructions = function
  | c :: rest ->
    let* c_anf = anf_construction c in
    let* rest_anf = anf_constructions rest in
    return (c_anf :: rest_anf)
  | [] -> return []
;;

module IdentSet = Set.Make (struct
    type t = ident

    let compare = compare
  end)

let pp_identset fmt s =
  Format.fprintf fmt "{";
  IdentSet.iter (fun (Ident id) -> Format.fprintf fmt "%s; " id) s;
  Format.fprintf fmt "}"
;;

let free_vars_imm immexpr =
  match immexpr with
  | ImmId id -> IdentSet.singleton id
  | ImmNum _ -> IdentSet.empty
;;

let rec free_vars_aexpr (expr : aexpr) : IdentSet.t =
  match expr with
  | ALet (id, cexpr, body) ->
    let fv_c = free_vars_cexpr cexpr in
    let fv_b = free_vars_aexpr body in
    IdentSet.union fv_c (IdentSet.remove id fv_b)
  | ACExpr c -> free_vars_cexpr c

and free_vars_cexpr cexpr =
  match cexpr with
  | CImmexpr imm -> free_vars_imm imm
  (* | CBinop (_, ImmId l, ImmId r) -> IdentSet.of_list [l; r] *)
  | CBinop (_, l, r) -> IdentSet.union (free_vars_imm l) (free_vars_imm r)
  | CApp (ImmId f, args) ->
    let fv_args =
      List.fold_left
        (fun acc arg ->
           match arg with
           | ImmId id -> IdentSet.add id acc
           | _ -> acc)
        IdentSet.empty
        args
    in
    IdentSet.add f fv_args
  | CApp (_, args) ->
    List.fold_left
      (fun acc arg ->
         match arg with
         | ImmId id -> IdentSet.add id acc
         | _ -> acc)
      IdentSet.empty
      args
  | CLam (param, body) ->
    let fv_body = free_vars_aexpr body in
    Format.printf
      "Free vars in lambda (param=%s): %a@."
      (show_ident param)
      pp_identset
      fv_body;
    IdentSet.remove param fv_body
  | CIte (cond, t, fopt) ->
    let fv_cond = free_vars_cexpr cond in
    let fv_t = free_vars_aexpr t in
    let fv_f =
      match fopt with
      | Some e -> free_vars_aexpr e
      | None -> IdentSet.empty
    in
    IdentSet.union fv_cond (IdentSet.union fv_t fv_f)
;;

(* let is_lam = function  *)

let rec lift_aexpr aexpr lifted_functions =
  match aexpr with
  (* | ALet (varname, CLam (id, ae), body) ->
    let lifted_functions = (varname, CLam (id, ae)) :: lifted_functions in
    Stdlib.Format.printf "CLam %a@. %a\n" pp_cexpr (CLam (id, ae)) pp_ident varname;
    return (body, lifted_functions) *)
  | ALet (varname, cexpr, body) ->
    let* liftedc, lifted_functions2 = lift_cexpr cexpr lifted_functions in
    let* liftedb, lifted_functions3 = lift_aexpr body lifted_functions2 in
    (* Stdlib.Format.printf "ALet liftedc %a@.\n" pp_cexpr liftedc;
    Stdlib.Format.printf "ALet liftedb %a@.\n" pp_aexpr liftedb; *)
    return (ALet (varname, liftedc, liftedb), lifted_functions3)
  (* | ACExpr (CLam (id, body)) ->
    let* lifted, lifted_functions = lift_aexpr body lifted_functions in
    return (ACExpr (CLam (id, lifted)), lifted_functions) *)
  | ACExpr cexpr ->
    let* lifted, lifted_functions = lift_cexpr cexpr lifted_functions in
    (* Stdlib.Format.printf "ACExpr lifted %a@.\n" pp_cexpr lifted; *)
    return (ACExpr lifted, lifted_functions)

and lift_cexpr cexpr lifted_functions =
  match cexpr with
  | CLam (id, body) ->
    let* lifted, lifted_functions = lift_aexpr body lifted_functions in
    return (CLam (id, lifted), lifted_functions)
  | CIte (ccond, thn, Some els) ->
    let* lifted_thn, lifted_functions2 = lift_aexpr thn lifted_functions in
    let* lifted_els, lifted_functions3 = lift_aexpr els lifted_functions2 in
    return (CIte (ccond, lifted_thn, Some lifted_els), lifted_functions3)
  | CIte (ccond, thn, None) ->
    let* lifted_thn, lifted_functions2 = lift_aexpr thn lifted_functions in
    return (CIte (ccond, lifted_thn, None), lifted_functions2)
  | c -> return (c, lifted_functions)
;;

(* | CBinop of cbinop * immexpr * immexpr
  | CIte of cexpr * aexpr * aexpr option (* if (42 > a) then 42 else a *)
  | CImmexpr of immexpr
  | CLam of ident * aexpr (* fun a -> a + 42 *)
  | CApp of immexpr * immexpr list *)
let lift_aconstruction ac lifted_functions =
  match ac with
  | AExpr ae ->
    let* ae', lifted_functions = lift_aexpr ae lifted_functions in
    (* let _ = free_vars_aexpr ae in *)
    return (AExpr ae', lifted_functions)
  | AStatement (flag, [ (id, ae) ]) ->
    let* ae', lifted_functions = lift_aexpr ae lifted_functions in
    (* let _ = free_vars_aexpr ae in *)
    return (AStatement (flag, [ id, ae' ]), lifted_functions)
  | a -> return (a, lifted_functions)
;;

let rec lift_aconstructions acs lifted_functions =
  match acs with
  | [] -> return ([], lifted_functions)
  | ac :: rest ->
    let* ac', lifted_functions2 = lift_aconstruction ac lifted_functions in
    let* rest', lifted_functions3 = lift_aconstructions rest lifted_functions2 in
    return (ac' :: rest', lifted_functions3)
;;

let lift_program acs =
  let lifted_functions = !pre_lifted_functions @ !pre_lifted_letins in
  (* reset global state *)
  (* let* acs', lifted_functions = lift_aconstructions acs lifted_functions in *)
  let lifted_top_level =
    List.map (fun (id, ce) -> AStatement (Nonrec, [ id, ACExpr ce ])) lifted_functions
  in
  return (lifted_top_level @ acs)
;;

(* let pp_identset fmt s =
  Format.fprintf fmt "{";
  IdentSet.iter (fun (Ident id) -> Format.fprintf fmt "%s; " id) s;
  Format.fprintf fmt "}"
;; *)

module IdentMap = Map.Make(struct
  type t = ident
  let compare = compare
end)

let collect_freevars_map (lams : (ident * cexpr) list) : IdentSet.t IdentMap.t =
  List.fold_left
    (fun acc (id, expr) ->
       let fv = free_vars_cexpr expr in
       IdentMap.add id fv acc)
    IdentMap.empty
    lams

let add_args (lams : (ident * cexpr) list) : (ident * cexpr) list =
  List.map
    (fun (id, expr) ->
       let fv = free_vars_cexpr expr in
       let fv_list = IdentSet.elements fv in
       let wrapped =
         List.fold_right (fun fv_id acc -> CLam (fv_id, ACExpr acc)) fv_list expr
       in
       id, wrapped)
    lams
;;
let rec apply_lifted_args_aexpr env (ae : aexpr) : aexpr =
  match ae with
  | ALet (id, ce, body) ->
      ALet (id, apply_lifted_args_cexpr env ce,
                 apply_lifted_args_aexpr env body)
  | ACExpr c ->
      ACExpr (apply_lifted_args_cexpr env c)

and apply_lifted_args_cexpr env (ce : cexpr) : cexpr =
  match ce with
  | CImmexpr (ImmId lam_id) when IdentMap.mem lam_id env ->
      let fv = IdentSet.elements (IdentMap.find lam_id env) in
      CApp (ImmId lam_id, List.map (fun v -> ImmId v) fv)

  | CApp (ImmId f, args) ->
      let new_args = List.map (apply_lifted_args_imm env) args in
      CApp (ImmId f, new_args)

  | CLam (id, body) ->
      CLam (id, apply_lifted_args_aexpr env body)

  | CIte (cond, thn, els) ->
      CIte (apply_lifted_args_cexpr env cond,
            apply_lifted_args_aexpr env thn,
            Option.map (apply_lifted_args_aexpr env) els)

  | CBinop (op, l, r) ->
      CBinop (op, apply_lifted_args_imm env l, apply_lifted_args_imm env r)

  | _ -> ce

and apply_lifted_args_imm env = function
  | ImmId id when IdentMap.mem id env ->
      ImmId id
  | imm -> imm

let apply_lifted_args_aconstruction env = function
  | AExpr ae ->
      AExpr (apply_lifted_args_aexpr env ae)
  | AStatement (flag, binds) ->
      let binds' =
        List.map (fun (id, ae) -> id, apply_lifted_args_aexpr env ae) binds
      in
      AStatement (flag, binds')


let anf_and_lift_program ast =
  let* anf_program = anf_constructions ast in
  let fv_map = collect_freevars_map !pre_lifted_functions in
  let wrapped = add_args !pre_lifted_functions in
  let letins = 
    List.map (fun (id, expr) -> id, apply_lifted_args_cexpr fv_map expr) !pre_lifted_letins in
  let anf_program_with_apps =
    List.map (apply_lifted_args_aconstruction fv_map) anf_program
  in
  pre_lifted_functions := wrapped;
  pre_lifted_letins := letins;
  List.iter
    (fun (id, expr) ->
       (* let fv = free_vars_cexpr expr in *)
       Format.printf "wrapped %a@. %a\n" pp_cexpr expr pp_ident id)
       (* Format.printf "Free vars in %s: %a@." (show_ident id) pp_identset fv) *)
    wrapped;
  (* pre_lifted_functions := add_args !pre_lifted_functions; *)
  lift_program anf_program_with_apps
;;
