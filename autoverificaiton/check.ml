open Z3
open Z3.Solver
open Z3.Goal

type smt_result = SmtSat of Model.model | SmtUnsat | Timeout

let solver_result solver =
  (* let _ = printf "solver_result\n" in *)
  match check solver [] with
  | UNSATISFIABLE -> SmtUnsat
  | UNKNOWN ->
      (* raise (InterExn "time out!") *)
      (* Printf.printf "\ttimeout\n"; *)
      Timeout
  | SATISFIABLE -> (
      match Solver.get_model solver with
      | None -> failwith "never happen"
      | Some m -> SmtSat m)

let get_int m i =
  match Model.eval m i true with
  | None -> failwith "get_int"
  | Some v ->
      (* printf "get_int(%s)\n" (Expr.to_string i); *)
      int_of_string @@ Arithmetic.Integer.numeral_to_string v

let get_bool_str m i =
  match Model.eval m i true with None -> "none" | Some v -> Expr.to_string v

let get_int_name ctx m name =
  get_int m @@ Z3.Arithmetic.Integer.mk_const_s ctx name

let get_pred m predexpr =
  match Model.eval m predexpr true with
  | None -> failwith "get pred"
  | Some v -> (
      match Boolean.get_bool_value v with
      | Z3enums.L_TRUE -> true
      | Z3enums.L_FALSE -> false
      | Z3enums.L_UNDEF -> failwith "get pred")

let get_unknown_fv ctx m unknown_fv =
  List.map (fun (_, b) -> get_pred m (Boolean.mk_const_s ctx b)) unknown_fv

let ctx =
  Z3.mk_context [ ("model", "true"); ("proof", "false"); ("timeout", "1999") ]

let smt_solve ctx vc =
  (* let _ = printf "check\n" in *)
  let solver = mk_solver ctx None in
  let g = mk_goal ctx true false false in
  (* let () = Printf.printf "Q: %s\n" @@ Frontend.pretty_layout vc in *)
  let () = Printf.printf "Q: %s\n" @@ Frontend.coq_layout vc in
  let q = Query.to_z3 ctx vc in
  let _ = Goal.add g [ q ] in
  (* let g = Z3.Goal.simplify g None in *)
  (* let g = *)
  (*   Z3.Tactic.(ApplyResult.get_subgoal (apply (mk_tactic ctx "snf") g None) 0) *)
  (* in *)
  let () =
    Printf.printf "Goal: %s\n"
    @@ Zzdatatype.Datatype.List.split_by "\n" Z3.Expr.to_string
    @@ Z3.Goal.get_formulas g
  in
  let _ = Solver.add solver (get_formulas g) in
  solver_result solver
