open Prop.T
open Z3aux
open Z3

let make_forall ctx qv body =
  if List.length qv == 0 then body
  else
    Quantifier.expr_of_quantifier
      (Quantifier.mk_forall_const ctx qv body (Some 1) [] [] None None)

let make_exists ctx qv body =
  if List.length qv == 0 then body
  else
    Quantifier.expr_of_quantifier
      (Quantifier.mk_exists_const ctx qv body (Some 1) [] [] None None)

let z3func ctx funcname inptps outtp =
  FuncDecl.mk_func_decl ctx
    (Symbol.mk_string ctx funcname)
    (List.map (tp_to_sort ctx) inptps)
    (tp_to_sort ctx outtp)

let to_z3 ctx prop =
  let get_ty x =
    x.ty
    (* match x.ty with *)
    (* | None -> failwith (Printf.sprintf "untyped prop variable %s" x.x) *)
    (* | Some ty -> ty *)
  in
  let rec aux prop =
    match prop with
    | True -> bool_to_z3 ctx true
    | Var x -> tpedvar_to_z3 ctx (get_ty x, x.x)
    | Implies (p1, p2) -> Z3.Boolean.mk_implies ctx (aux p1) (aux p2)
    | Ite (p1, p2, p3) -> Z3.Boolean.mk_ite ctx (aux p1) (aux p2) (aux p3)
    | Not p -> Z3.Boolean.mk_not ctx (aux p)
    | And ps -> Z3.Boolean.mk_and ctx (List.map aux ps)
    | Or ps -> Z3.Boolean.mk_or ctx (List.map aux ps)
    | Iff (p1, p2) -> Z3.Boolean.mk_iff ctx (aux p1) (aux p2)
    | Forall (u, body) -> make_forall ctx [ aux (Var u) ] (aux body)
    | Exists (u, body) -> make_exists ctx [ aux (Var u) ] (aux body)
    | MethodPred (mp, args) -> (
        let argsty = List.map get_ty args in
        let args = List.map (fun x -> aux (Var x)) args in
        match (mp, args) with
        | "==", [ a; b ] -> Z3.Boolean.mk_eq ctx a b
        | "==", _ -> failwith "wrong prop with operator =="
        | "!=", [ a; b ] -> Z3.Boolean.(mk_not ctx @@ mk_eq ctx a b)
        | "!=", _ -> failwith "wrong prop with operator !="
        | "<=", [ a; b ] -> Z3.Arithmetic.mk_le ctx a b
        | "<=", _ -> failwith "wrong prop with operator <="
        | ">=", [ a; b ] -> Z3.Arithmetic.mk_ge ctx a b
        | ">=", _ -> failwith "wrong prop with operator >="
        | "<", [ a; b ] -> Z3.Arithmetic.mk_lt ctx a b
        | "<", _ -> failwith "wrong prop with operator <"
        | ">", [ a; b ] -> Z3.Arithmetic.mk_gt ctx a b
        | ">", _ -> failwith "wrong prop with operator >"
        | mp, args ->
            let func = z3func ctx mp argsty T.Bool in
            Z3.FuncDecl.apply func args)
  in
  aux prop
