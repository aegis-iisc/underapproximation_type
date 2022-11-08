Set Warnings "-notation-overridden,-parsing".
From PLF Require Import Maps.
From Coq Require Import Lists.List.
Import ListNotations.

Definition linear_context (A : Type) := list (string * A).

Definition l_empty {A:Type} : linear_context A := nil.

(* Implemenetd as find the right most one *)

Fixpoint l_find_right_most {A:Type} (ctx: linear_context A) (name: string) :=
  match ctx with
  | [] => None
  | (x, xty)::ctx =>
      match l_find_right_most ctx name with
      | None => if String.eqb x name then Some xty else None
      | Some xty => Some xty
      end
  end.

Definition l_append {A : Type} (m : linear_context A) (x : string) (v : A) : linear_context A := m ++ [(x, v)].

(* Not same name *)
Definition linear_context_inv {A:Type} (ctx: linear_context A) := True.

Notation " m '<l>' x ':l:' ty " := (l_append m x ty) (at level 80).

Global Hint Rewrite app_nil_l: core.
Global Hint Rewrite app_nil_r: core.

(* Some lemmas. *)

Lemma app_one_eq_nil {A: Type}: forall (x: string) (tau:A) Gamma, ~ ([] = Gamma ++ [(x, tau)]).
Proof.
  intros. intro H. symmetry in H. apply app_eq_nil in H. destruct H. inversion H0.
Qed.

Lemma app_one_is_cons {A: Type}: forall (x: A) l, (x::nil) ++ l = x :: l.
Proof. simpl. reflexivity. Qed.

Lemma app_list_unit_eq_unit {A: Type}: forall (x y: A) l, l ++ [x] = [y] -> x = y /\ l = [].
Proof. intros. apply app_eq_unit in H.
       destruct H.
       destruct H. inversion H0. split; auto.
       destruct H. inversion H0.
Qed.

Global Hint Resolve app_list_unit_eq_unit: core.

Lemma l_find_right_most_none_neq_hd {A: Type}: forall (Gamma: linear_context A) x tx a,
    l_find_right_most ((x, tx):: Gamma) a = None -> x <> a.
Proof with auto.
  intros. simpl in H.
  destruct (l_find_right_most Gamma a). inversion H.
  destruct (eqb_spec x a)... inversion H.
Qed.

Global Hint Resolve l_find_right_most_none_neq_hd: core.

Lemma l_find_right_most_none_neq_tl {A: Type}: forall (Gamma: linear_context A) x tx a,
    l_find_right_most ((x, tx):: Gamma) a = None -> l_find_right_most Gamma a = None.
Proof with auto.
  intros. simpl in H.
  destruct (l_find_right_most Gamma a). inversion H.
  destruct (eqb_spec x a)...
Qed.

Global Hint Resolve l_find_right_most_none_neq_tl: core.

Lemma l_find_right_most_weak_pre {A: Type}: forall (Gamma1 Gamma2 : linear_context A) a,
    l_find_right_most (Gamma1 ++ Gamma2) a = None ->
    l_find_right_most Gamma1 a = None.
Proof with auto.
  induction Gamma1; simpl; intros Gamma2 x H...
  destruct a.
  destruct (l_find_right_most (Gamma1 ++ Gamma2) x) eqn: H1H... inversion H.
  destruct (eqb_spec s x); subst... inversion H.
  apply IHGamma1 in H1H.
  destruct (l_find_right_most Gamma1 x) eqn: HH...
Qed.

Global Hint Resolve l_find_right_most_weak_pre: core.

Lemma l_find_right_most_weak_post {A: Type}: forall (Gamma1  Gamma2: linear_context A) a,
    l_find_right_most (Gamma1 ++ Gamma2) a = None ->
    l_find_right_most Gamma2 a = None.
Proof with auto.
  induction Gamma1; simpl; intros Gamma2 x H...
  destruct a.
  destruct (l_find_right_most (Gamma1 ++ Gamma2) x) eqn: H1H... inversion H.
Qed.

Global Hint Resolve l_find_right_most_weak_post: core.

Lemma l_find_right_most_weak_unit {A: Type}: forall x (tau_x: A) a,
    l_find_right_most ((x, tau_x)::nil) a = None -> a <> x.
Proof with auto.
  intros. inversion H.
  destruct (eqb_spec x a); subst... inversion H1.
Qed.


Global Hint Resolve l_find_right_most_weak_unit: core.

Lemma l_find_implies_in {A:Type}: forall (ctx: linear_context A) (name: string) (tau: A),
      l_find_right_most ctx name = Some tau ->
      In (name, tau) ctx.
Proof with eauto.
  induction ctx; intros...
  - inversion H.
  - destruct a. inversion H.
    destruct (l_find_right_most ctx name) eqn: HH.
    + inversion H1; subst... assert (In (name, tau) ctx)... apply in_cons...
    + destruct (eqb_spec s name); subst... inversion H1; subst. apply in_eq...
      simpl in H. rewrite HH in H. destruct (eqb_spec s name); subst... exfalso... inversion H1.
Qed.

Lemma l_find_right_most_some_spec {A:Type}: forall (ctx: linear_context A) (name: string) (tau: A),
  l_find_right_most ctx name = Some tau ->
  (exists ctx1 ctx2,
      ctx = ctx1 ++ ((name, tau)::nil) ++ ctx2 /\ l_find_right_most ctx2 name = None
  ).
Proof with auto.
Admitted.
(*   intros. *)
(*   apply l_find_implies_in in H. apply in_split in H. destruct H as (G1 & G2 & HG12). *)
(*   exists G1, G2. subst. split... *)
(* Qed. *)


(* Declare Scope linear_context_scope. *)
(* Notation "G[ ]" := nil (format "G[ ]") : linear_context_scope. *)
(* Notation " context 'G::' x " := (cons x context) (at level 80) : linear_context_scope. *)
(* Notation "G[ x ]" := (cons x nil) : linear_context_scope. *)
(* Notation "G[ x ; y ]" := (cons y (cons x nil)) : linear_context_scope. *)
(* Notation "G[ x ; y ; z ]" := (cons z (cons y (cons x nil))) : linear_context_scope. *)
(* Notation "G[ x ; y ; z ; a ]" := (cons a (cons z (cons y (cons x nil)))) : linear_context_scope. *)
