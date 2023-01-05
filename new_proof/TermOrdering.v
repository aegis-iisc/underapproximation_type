From stdpp Require Import mapset.
From Coq Require Import Logic.ClassicalFacts.
From Coq Require Import Classical.
From CT Require Import CoreLang.
From CT Require Import CoreLangProp.
From CT Require Import OperationalSemanticsProp.
From CT Require Import ErrOperationalSemanticsProp.
From CT Require Import BasicTypingProp.
From CT Require Import SyntaxSugar.

Import Atom.
Import CoreLang.
Import Tactics.
Import NamelessTactics.
Import OperationalSemantics.
Import OperationalSemanticsProp.
Import ErrOperationalSemantics.
Import ErrOperationalSemanticsProp.
Import BasicTyping.
Import ListCtx.
Import SyntaxSugar.

Definition env := listctx value.
Fixpoint tm_msubst (ss:env) (t:tm) : tm :=
  match ss with
  | nil => t
  | ((x,s)::ss') => tm_msubst ss' ({x := s}t t)
  end.

Fixpoint value_msubst (ss:env) (t:value) : value :=
  match ss with
  | nil => t
  | ((x,s)::ss') => value_msubst ss' ({x := s}v t)
  end.

Inductive instantiation : (listctx ty) -> env -> Prop :=
| instantiation_nil: instantiation [] []
| instantiation_cons: forall x T (v: value) c e,
    [] ⊢t v ⋮v T ->
    x ∉ ctxdom c ->
    instantiation c e ->
    instantiation ((x, T) :: c) ((x, v) :: e).

Global Hint Constructors instantiation: core.

Lemma instantiation_regular_ok: forall Γt Γv, instantiation Γt Γv -> ctxdom Γt = ctxdom Γv /\ ok Γt /\ ok Γv.
Proof.
  intros. induction H; repeat destruct_hyp_conj; repeat split; intros; auto;
    try  listctx_set_solver;
  try (simpl; rewrite H2; auto; try listctx_set_solver).
  - rewrite ok_pre_destruct; split; auto. rewrite <- H2; auto.
Qed.

Lemma instantiation_regular_lc: forall Γt Γv, instantiation Γt Γv -> (forall x v, ctxfind Γv x = Some v -> lc v).
Proof.
  intros. assert (ok Γv). apply instantiation_regular_ok in H. repeat destruct_hyp_conj; auto.
  induction H; simpl; auto.
  - simpl in H0. listctx_set_solver.
  - simpl in H0. repeat var_dec_solver; basic_typing_solver.
Qed.

Lemma instantiation_regular_closed: forall Γt Γv, instantiation Γt Γv -> (forall x v, ctxfind Γv x = Some v -> closed_value v).
Proof.
  intros. assert (ok Γv). apply instantiation_regular_ok in H. repeat destruct_hyp_conj; auto.
  induction H; auto.
  - listctx_set_solver.
  - simpl in H0. repeat var_dec_solver;
    basic_typing_solver3.
Qed.

Lemma instantiation_regular: forall Γt Γv, instantiation Γt Γv ->
                                      (forall x v, ctxfind Γv x = Some v -> lc v) /\
                                        (forall x v, ctxfind Γv x = Some v -> closed_value v) /\
                                        ctxdom Γt = ctxdom Γv /\ ok Γt /\ ok Γv.
Proof.
  intros. split.
  eapply instantiation_regular_lc; eauto.
  split.
  eapply instantiation_regular_closed; eauto.
  apply instantiation_regular_ok; auto.
Qed.


Lemma tm_msubst_closed: ∀ e, closed_tm e -> (forall ss, tm_msubst ss e = e).
Proof.
  unfold closed_tm.
  intros.
  induction ss; simpl; auto.
  destruct a. rewrite subst_fresh_tm; auto. fast_set_solver!!.
Qed.

Lemma value_msubst_closed: ∀ e, closed_value e -> (forall ss, value_msubst ss e = e).
Proof.
  unfold closed_value.
  intros.
  induction ss; simpl; auto.
  destruct a. rewrite subst_fresh_value; auto. fast_set_solver!!.
Qed.

Lemma instantiation_R : ∀ c e,
    instantiation c e →
    ∀ x t T,
      ctxfind c x = Some T →
      ctxfind e x = Some t → [] ⊢t t ⋮t T.
Proof.
  intros c e V. induction V; simpl ; intros.
  - inversion H.
  - repeat var_dec_solver.
    eapply IHV; eauto.
Qed.

Lemma instantiation_R_exists : ∀ c e,
    instantiation c e →
    ∀ x T,
      ctxfind c x = Some T →
      (exists t, ctxfind e x = Some t /\ [] ⊢t t ⋮t T /\ closed_value t).
Proof.
  intros c e V. induction V; simpl ; intros.
  - inversion H.
  - repeat var_dec_solver. exists v. split; auto. split; auto; basic_typing_solver3.
Qed.

Lemma msubst_var: ∀ ss (x: atom) (v: value), closed_value v -> ctxfind ss x = Some v -> value_msubst ss x = v.
Proof.
  induction ss; simpl; intros.
  - inversion H0.
  - destruct a. repeat var_dec_solver. rewrite value_msubst_closed; auto.
Qed.

Lemma msubst_var_none: ∀ ss (x: atom), ctxfind ss x = None -> value_msubst ss x = x.
Proof.
  induction ss; simpl; intros; auto.
  - destruct a. repeat var_dec_solver.
Qed.

Lemma msubst_vlam: ∀ ss Tx e, value_msubst ss (vlam Tx e) = vlam Tx (tm_msubst ss e).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_open_tm: ∀ Γv e k (x: atom),
  ok Γv ->
  (forall x v, ctxfind Γv x = Some v -> closed_value v /\ lc v) ->
  x ∉ ctxdom Γv ->
  {k ~t> x} (tm_msubst Γv e) = tm_msubst Γv ({k ~t> x} e).
Proof.
  induction Γv; simpl; intros; auto.
  - auto_destruct_pair.
    assert (closed_value v /\ lc v). eapply (H0 a v); eauto. repeat var_dec_solver.
    rewrite subst_open_var_tm.
    rewrite IHΓv; auto. listctx_set_solver.
    intros. specialize (H0 x0 v0). repeat var_dec_solver. apply ctxfind_some_implies_in_dom in H3. rewrite ok_pre_destruct in H. destruct H. fast_set_solver. fast_set_solver. fast_set_solver. destruct H2; auto.
Qed.

Lemma msubst_open_value: ∀ Γv e k (x: atom),
  ok Γv ->
  (forall x v, ctxfind Γv x = Some v -> closed_value v /\ lc v) ->
  x ∉ ctxdom Γv ->
  {k ~v> x} (value_msubst Γv e) = value_msubst Γv ({k ~v> x} e).
Proof.
  induction Γv; simpl; intros; auto.
  - auto_destruct_pair.
    assert (closed_value v /\ lc v). eapply (H0 a v); eauto. repeat var_dec_solver.
    rewrite subst_open_var_value.
    rewrite IHΓv; auto. listctx_set_solver.
    intros. specialize (H0 x0 v0). repeat var_dec_solver. apply ctxfind_some_implies_in_dom in H3. rewrite ok_pre_destruct in H. destruct H. fast_set_solver. fast_set_solver. fast_set_solver. destruct H2; auto.
Qed.

Ltac instantiation_regular_solver :=
  match goal with
  | [H: instantiation ?a ?b |- _ ∉ _ ] =>
      apply instantiation_regular in H; repeat destruct_hyp_conj; auto; listctx_set_simpl; set_solver
  | [H: instantiation ?a ?b |- ok _ ] =>
      apply instantiation_regular_ok in H; repeat destruct_hyp_conj; auto; listctx_set_solver
  | [H: instantiation ?a ?b |- forall x v, ctxfind ?b x = Some v -> _ ] =>
      apply instantiation_regular in H; repeat destruct_hyp_conj; eauto; listctx_set_solver
  end.

Lemma msubst_vfix: ∀ ss Tx (e: value), value_msubst ss (vfix Tx e) = vfix Tx (value_msubst ss e).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_value: ∀ ss (v: value), tm_msubst ss v = tvalue (value_msubst ss v).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_tlete: ∀ ss e1 e2, tm_msubst ss (tlete e1 e2) = tlete (tm_msubst ss e1) (tm_msubst ss e2).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_tletbiop: ∀ ss op v1 v2 e,
    tm_msubst ss (tletbiop op v1 v2 e) = tletbiop op (value_msubst ss v1) (value_msubst ss v2) (tm_msubst ss e).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_tletapp: ∀ ss v1 v2 e,
    tm_msubst ss (tletapp v1 v2 e) = tletapp (value_msubst ss v1) (value_msubst ss v2) (tm_msubst ss e).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_tmatchb: ∀ ss v e1 e2,
    tm_msubst ss (tmatchb v e1 e2) = tmatchb (value_msubst ss v) (tm_msubst ss e1) (tm_msubst ss e2).
Proof.
  induction ss; simpl; intros; auto; auto_destruct_pair.
  eapply IHss.
Qed.

Lemma msubst_vbvar: ∀ ss k, value_msubst ss (vbvar k) = (vbvar k).
Proof.
  induction ss; simpl; intros; mydestr; auto.
Qed.

Lemma msubst_terr: ∀ ss, tm_msubst ss terr = terr.
Proof.
  induction ss; simpl; intros; auto.
  - destruct a. auto.
Qed.

Ltac msubst_simpl :=
  repeat match goal with
    | [H: context [value_msubst ?env (vbvar ?k)] |- _ ] =>
        setoid_rewrite (msubst_vbvar env k) in H
    | [ |- context [value_msubst ?env (vbvar ?k)] ] =>
        setoid_rewrite (msubst_vbvar env k)
    | [H: context [value_msubst ?env (vlam ?Tx ?e)] |- _ ] =>
        setoid_rewrite (msubst_vlam env Tx) in H
    | [ |- context [value_msubst ?env (vlam ?Tx ?e)] ] =>
        setoid_rewrite (msubst_vlam env Tx)
    | [H: context [value_msubst ?env (vfix ?Tx ?e)] |- _ ] =>
        setoid_rewrite (msubst_vfix env Tx) in H
    | [ |- context [value_msubst ?env (vfix ?Tx ?e)] ] =>
        setoid_rewrite (msubst_vfix env Tx)
    | [H: context [tm_msubst ?env (tvalue ?v)] |- _ ] =>
        setoid_rewrite (msubst_value env v) in H
    | [ |- context [tm_msubst ?env (tvalue ?v)] ] =>
        setoid_rewrite (msubst_value env v)
    | [H: context [tm_msubst ?env (tlete ?e1 ?e2)] |- _ ] =>
        setoid_rewrite (msubst_tlete env e1 e2) in H
    | [ |- context [tm_msubst ?env (tlete ?e1 ?e2)] ] =>
        setoid_rewrite (msubst_tlete env e1 e2)
    | [H: context [tm_msubst ?env (tletbiop ?op ?v1 ?v2 ?e)] |- _ ] =>
        setoid_rewrite (msubst_tletbiop env op v1 v2 e) in H
    | [ |- context [tm_msubst ?env (tletbiop ?op ?v1 ?v2 ?e)] ] =>
        setoid_rewrite (msubst_tletbiop env op v1 v2 e)
    | [H: context [tm_msubst ?env (tletapp ?v1 ?v2 ?e)] |- _ ] =>
        setoid_rewrite (msubst_tletapp env v1 v2 e) in H
    | [ |- context [tm_msubst ?env (tletapp ?v1 ?v2 ?e)] ] =>
        setoid_rewrite (msubst_tletapp env v1 v2 e)
    | [H: context [tm_msubst ?env (tmatchb ?v ?e1 ?e2)] |- _ ] =>
        setoid_rewrite (msubst_tmatchb env v e1 e2) in H
    | [ |- context [tm_msubst ?env (tmatchb ?v ?e1 ?e2)] ] =>
        setoid_rewrite (msubst_tmatchb env v e1 e2)
    | [H: context [tm_msubst ?env terr] |- _ ] => rewrite (msubst_terr env) in H
    | [ |- context [tm_msubst ?env terr] ] => rewrite (msubst_terr env)
    end.

Lemma closed_has_type_under_any_ctx_value: forall Γ (v: value) T, Γ ⊢t v ⋮v T -> closed_value v -> (forall Γ', ok Γ' -> Γ' ⊢t v ⋮v T).
Proof.
  intros. apply closed_has_type_under_empty_value in H; auto. basic_typing_solver2.
Qed.

Lemma closed_has_type_under_any_ctx_tm: forall Γ (v: tm) T, Γ ⊢t v ⋮t T -> closed_tm v -> (forall Γ', ok Γ' -> Γ' ⊢t v ⋮t T).
Proof.
  intros. apply closed_has_type_under_empty_tm in H; auto. basic_typing_solver2.
Qed.

Ltac msubst_preserves_typing_tac :=
  match goal with
  | [a: atom |- _ ] => repeat specialize_with a
  end;
  repeat match goal with
    | [|- _ ⊢t ((tm_msubst _ _) ^t^ _) ⋮t _ ] =>
        rewrite msubst_open_tm; try instantiation_regular_solver; try fast_set_solver
    | [|- _ ⊢t ((value_msubst _ _) ^v^ _) ⋮v _ ] =>
        rewrite msubst_open_value; try instantiation_regular_solver; try fast_set_solver
    | [H: context [_ ⊢t (tm_msubst _ _) ⋮t ?T] |- _ ⊢t _ ⋮t ?T] =>
        eapply H; eauto; try (rewrite app_assoc; auto)
    end.

Ltac msubst_preserves_typing_tac2 :=
  (repeat match goal with
     | [|- closed_value _] => unfold closed_value; intros; listctx_set_solver
     | [ |- _ ⊢t mk_app _ _ ⋮t ?T ] => eapply mk_app_typable; eauto
     | [ |- _ ⊢t (value_msubst _ _) ⋮v ?T ] => rewrite value_msubst_closed
     | [ |- _ ⊢t (tvalue (value_msubst _ _)) ⋮t ?T ] => rewrite value_msubst_closed
     end; basic_typing_solver2).

Lemma msubst_preserves_typing_tm_aux: ∀ Γ e T,
    Γ ⊢t e ⋮t T -> (forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (tm_msubst Γv e) ⋮t T).
Proof.
  apply (tm_has_type_mutual_rec
           (fun Γ v T P => forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (value_msubst Γv v) ⋮v T)
           (fun Γ e T P => forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (tm_msubst Γv e) ⋮t T)
        ); simpl; intros; subst; listctx_set_simpl; repeat destruct_hyp_conj; msubst_simpl; eauto;
  try (msubst_preserves_typing_tac2; constructor; listctx_set_solver);
  try (auto_exists_L; simpl; intros; msubst_preserves_typing_tac).
  - assert (forall x v, ctxfind Γv x = Some v -> closed_value v). eapply instantiation_regular_closed; eauto.
    rewrite ctxfind_app in e; auto. destruct e.
    + eapply instantiation_R_exists in H0; eauto. destruct H0 as (v & Hv1 & Hv2 & Hv3).
      erewrite msubst_var; eauto. basic_typing_solver2.
    + rewrite msubst_var_none; basic_typing_solver2.
      apply instantiation_regular_ok in H0. mydestr. rewrite <- H0.
      apply ctxfind_app_exclude in o. my_set_solver.
  - (* auto_exists_L; simpl; intros. repeat specialize_with f. *)
    msubst_preserves_typing_tac.
    specialize (H Γt (Γt' ++ [(f, Tx ⤍ T)]) Γv).
    rewrite msubst_vlam in H.
    rewrite msubst_open_tm; try instantiation_regular_solver. apply H; auto.
    rewrite app_assoc; auto.
Qed.

Lemma msubst_preserves_typing_tm: ∀ Γ Γv e T,
    Γ ⊢t e ⋮t T -> instantiation Γ Γv -> [] ⊢t (tm_msubst Γv e) ⋮t T.
Proof.
  intros. eapply msubst_preserves_typing_tm_aux; eauto. listctx_set_simpl.
Qed.

Lemma msubst_preserves_typing_value_aux: ∀ Γ (e: value) T,
    Γ ⊢t e ⋮v T -> (forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (value_msubst Γv e) ⋮v T).
Proof.
  apply (value_has_type_mutual_rec
           (fun Γ v T P => forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (value_msubst Γv v) ⋮v T)
           (fun Γ e T P => forall Γt Γt' Γv, Γ = Γt ++ Γt' -> instantiation Γt Γv -> Γt' ⊢t (tm_msubst Γv e) ⋮t T)
        ); simpl; intros; subst; listctx_set_simpl; repeat destruct_hyp_conj; msubst_simpl; eauto;
  try (msubst_preserves_typing_tac2; constructor; listctx_set_solver);
  try (auto_exists_L; simpl; intros; msubst_preserves_typing_tac).
  - assert (forall x v, ctxfind Γv x = Some v -> closed_value v). eapply instantiation_regular_closed; eauto.
    rewrite ctxfind_app in e; auto. destruct e.
    + eapply instantiation_R_exists in H0; eauto. destruct H0 as (v & Hv1 & Hv2 & Hv3).
      erewrite msubst_var; eauto. basic_typing_solver2.
    + rewrite msubst_var_none; basic_typing_solver2.
      apply instantiation_regular_ok in H0. repeat destruct_hyp_conj. rewrite <- H0.
      apply ctxfind_app_exclude in o. my_set_solver.
  - (* auto_exists_L; simpl; intros. repeat specialize_with f. *)
    msubst_preserves_typing_tac.
    specialize (H Γt (Γt' ++ [(f, Tx ⤍ T)]) Γv).
    rewrite msubst_vlam in H.
    rewrite msubst_open_tm; try instantiation_regular_solver. apply H; auto.
    rewrite app_assoc; auto.
Qed.

Lemma msubst_preserves_typing_value: ∀ Γ Γv e T,
    Γ ⊢t e ⋮v T -> instantiation Γ Γv -> [] ⊢t (value_msubst Γv e) ⋮v T.
Proof.
  intros. eapply msubst_preserves_typing_value_aux; eauto. listctx_set_simpl.
Qed.

Definition termRraw Γ e e' :=
forall env (v: value), instantiation Γ env ->
                  (tm_msubst env e) ↪* v -> (tm_msubst env e') ↪* v.

Global Hint Unfold termRraw: core.

Inductive termR: listctx ty -> ty -> tm -> tm -> Prop :=
| termR_c: forall Γ T (e e': tm),
    Γ ⊢t e ⋮t T -> Γ ⊢t e' ⋮t T -> termRraw Γ e e' -> termR Γ T e e'.

Notation " e1 '<-<{' Γ ';' T '}' e2 " := (termR Γ T e1 e2) (at level 10).
Notation " e1 '>=<{' Γ ';' T '}' e2 " := (termR Γ T e1 e2 /\ termR Γ T e2 e1) (at level 10).

Global Hint Constructors termR: core.

Lemma termR_refl: forall Γ T e, Γ ⊢t e ⋮t T -> termR Γ T e e.
Proof.
  intros. constructor; auto.
Qed.

Lemma termR_trans: forall Γ T e1 e2 e3, Γ ⊢t e1 ⋮t T -> Γ ⊢t e2 ⋮t T -> Γ ⊢t e3 ⋮t T ->
                                   termR Γ T e1 e2 -> termR Γ T e2 e3 -> termR Γ T e1 e3.
Proof.
  intros. invclear H2. invclear H3. constructor; auto.
Qed.

Lemma termRraw_emp: forall e e' T,
    [] ⊢t e ⋮t T -> [] ⊢t e' ⋮t T ->
    termRraw [] e e' -> (forall (v: value), e ↪* v -> e' ↪* v).
Proof.
  intros. unfold termRraw in H1. specialize (H1 [] v).
  rewrite tm_msubst_closed in H1; basic_typing_solver3.
  (* rewrite tm_msubst_closed in H1; basic_typing_solver3. *)
  (* apply H1; eauto. constructor. *)
Qed.

Definition value_inhabitant_oracle (T: ty) : value :=
  match T with
  | TBool => false
  | TNat => 0
  | T1 ⤍ T2 => vlam T1 terr
  end.

Lemma value_inhabitant_oracle_spec: forall Γ T, ok Γ -> Γ ⊢t value_inhabitant_oracle T ⋮v T.
Proof.
  intros. destruct T.
  - destruct b; constructor; auto.
  - auto_exists_L.
Qed.

Lemma value_inhabitant_oracle_spec_empty: forall T, [] ⊢t value_inhabitant_oracle T ⋮v T.
Proof.
  intros. apply value_inhabitant_oracle_spec; auto.
Qed.

Global Hint Resolve value_inhabitant_oracle_spec_empty: core.

Lemma instantiation_msubst_perserve_ty: forall Γ env e T,
    instantiation Γ env -> Γ ⊢t e ⋮t T -> [] ⊢t (tm_msubst env e) ⋮t T.
Proof.
  induction Γ; intros; invclear H; auto.
  simpl. apply IHΓ; auto. basic_typing_solver3.
Qed.

Lemma termR_tlete_dummy: forall Γ Tx T (e_x e: tm), Γ ⊢t e_x ⋮t Tx -> Γ ⊢t e ⋮t T -> (tlete e_x e) <-<{Γ;T} e.
Proof.
  intros. constructor; auto.
  - basic_typing_solver.
  - unfold termRraw. intros. msubst_simpl.
    rewrite lete_step_spec in H2; mydestr.
    eapply instantiation_msubst_perserve_ty in H1; eauto.
    lc_simpl.
Qed.

Ltac mk_app_perserve_termR_tac :=
  match goal with
  | [H: ?e ↪* (tvalue ?v),
        H': ∀ v1 : value, ?e ↪* (tvalue v1) → ?e' ↪* (tvalue v1) |-
                            exists v_x: value, ?e' ↪* (tvalue v_x) /\ _ ] => exists v; split; auto
  end.

Ltac termR_solver1 :=
  intros; auto;
  repeat match goal with
    | [H: ?e <-<{_;_} ?e' |- ?Γ ⊢t ?e' ⋮t _ ] => invclear H; mydestr; eauto
    | [H: ?e <-<{_;_} ?e' |- ?Γ ⊢t ?e ⋮t _ ] => invclear H; mydestr; eauto
    | [H: ?e <-<{_;_} ?e' |- ?e' ↪* _ ] => invclear H; mydestr; eauto
    | [ |- ?e <-<{_;_} ?e] => constructor; eauto
    | [H: termRraw [] ?e ?e' |- ?e' ↪* _ ] =>
        apply termRraw_emp in H; try basic_typing_solver3; eauto
    end.

Lemma instantiation_implies_open_msubst:
      ∀ Γ Γv, instantiation Γ Γv -> forall e T Tu k (u: value),
          Γ ⊢t e ⋮t T -> [] ⊢t u ⋮v Tu ->
                {k ~t> u} (tm_msubst Γv e) = tm_msubst Γv ({k ~t> u} e).
Proof.
  intros Γ Γv Hi. induction Hi; simpl; intros; auto.
  rewrite IHHi with (T:=T0) (Tu:=Tu); eauto.
  - rewrite -> subst_open_tm; basic_typing_solver3.
    rewrite subst_fresh_value; basic_typing_solver3.
  - basic_typing_solver3.
Qed.

Lemma instantiation_implies_close_msubst:
  ∀ Γ Γv, instantiation Γ Γv ->
                    forall e k (x: atom), x ∉ ctxdom Γ -> {k <t~ x} (tm_msubst Γv e) = tm_msubst Γv ({k <t~ x} e).
Proof.
  intros Γ Γv Hi. induction Hi; simpl; intros; auto.
  rewrite IHHi; try fast_set_solver.
  - rewrite -> subst_close_tm; basic_typing_solver3.
Qed.

Lemma instantiation_implies_msubst_lc:
      ∀ Γ Γv, instantiation Γ Γv -> forall e, lc e -> lc (tm_msubst Γv e).
Proof.
  intros Γ Γv Hi. induction Hi; simpl; intros; auto.
  - apply IHHi. apply subst_lc_tm; basic_typing_solver3.
Qed.

Lemma mk_app_perserve_termR: forall Γ Tx T(e1 e2 e1' e2': tm),
    e1 <-<{Γ;Tx ⤍ T} e1' -> e2 <-<{Γ;Tx} e2' -> (mk_app e1 e2) <-<{Γ;T} (mk_app e1' e2').
Proof.
  intros.
  constructor; auto.
  - eapply mk_app_typable; termR_solver1.
  - eapply mk_app_typable; termR_solver1.
  - intros. invclear H. invclear H0. unfold mk_app; intros; mydestr.
    unfold termRraw; intros. msubst_simpl.
    rewrite lete_step_spec in H6; simpl; mydestr. rewrite lete_step_spec; simpl.
    split.
    + unfold body in H0; mydestr. auto_exists_L; intros. lc_simpl.
      simpl in H8.
      assert (lc e2') as He2' by basic_typing_solver3.
      eapply instantiation_implies_msubst_lc in He2'; eauto.
      rewrite open_rec_lc_tm; basic_typing_solver3.
    + apply H3 in H7; auto. exists x. split; auto. lc_simpl.
      assert ([] ⊢t x ⋮v Tx ⤍ T).
      { eapply instantiation_msubst_perserve_ty in H2; eauto.
        basic_typing_solver3. }
      simpl in H8.
      erewrite instantiation_implies_open_msubst; eauto.
      erewrite instantiation_implies_open_msubst in H8; eauto.
      lc_simpl.
      rewrite lete_step_spec in H8; simpl; mydestr.
      rewrite lete_step_spec; simpl. split; auto.
      eexists; split; eauto.
Qed.

Lemma tyable_implies_terr_termR: forall (e: tm) Γ T, Γ ⊢t e ⋮t T -> terr <-<{ Γ; T} e.
Proof.
  intros. repeat split; auto.
  - constructor; basic_typing_solver2.
  - econstructor; eauto. msubst_simpl. auto_reduction_exfalso.
Qed.

Lemma tyable_implies_terr_termR_terr: forall (e: tm) Γ T1 T, Γ ⊢t e ⋮t T1 -> tlete e terr <-<{ Γ; T} terr.
Proof.
  intros. repeat split; auto.
  - auto_exists_L. intros. simpl. constructor. basic_typing_solver.
  - econstructor; basic_typing_solver.
  - econstructor; eauto. msubst_simpl. auto_reduction_exfalso.
Qed.

Lemma msubst_subst_commute_tm: forall Γ Γv,
    instantiation Γ Γv ->
    forall x u e, x ∉ ctxdom Γv -> closed_value u ->
             {x := u }t tm_msubst Γv e = tm_msubst Γv ({x := u }t e).
Proof.
  intros Γv Γ Hi; induction Hi; simpl; intros; mydestr; auto.
  rewrite IHHi; try fast_set_solver.
  rewrite subst_commute_tm; auto; basic_typing_solver3; set_solver.
Qed.

Lemma msubst_subst_commute_value: forall Γ Γv,
    instantiation Γ Γv ->
    forall x u e, x ∉ ctxdom Γv -> closed_value u ->
             {x := u }v value_msubst Γv e = value_msubst Γv ({x := u }v e).
Proof.
  intros Γv Γ Hi; induction Hi; simpl; intros; mydestr; auto.
  rewrite IHHi; try fast_set_solver.
  rewrite subst_commute_value; auto; basic_typing_solver3; set_solver.
Qed.

Lemma tm_msubst_mid_subst: forall Γv1 x u Γv2 Γ,
    instantiation Γ (Γv1 ++ (x, u) :: Γv2) -> closed_value u ->
    ∀ e, tm_msubst (Γv1 ++ (x, u) :: Γv2) e = tm_msubst (Γv1 ++ Γv2) ({x:= u}t e).
Proof.
  induction Γv1; simpl; intros; mydestr; auto.
  invclear H.
  erewrite IHΓv1; eauto. apply instantiation_regular in H7; mydestr. listctx_set_simpl.
  rewrite subst_commute_tm; auto; basic_typing_solver3; set_solver.
Qed.

Lemma value_msubst_mid_subst: forall Γv1 x u Γv2 Γ,
    instantiation Γ (Γv1 ++ (x, u) :: Γv2) -> closed_value u ->
    ∀ e, value_msubst (Γv1 ++ (x, u) :: Γv2) e = value_msubst (Γv1 ++ Γv2) ({x:= u}v e).
Proof.
  induction Γv1; simpl; intros; mydestr; auto.
  invclear H.
  erewrite IHΓv1; eauto. apply instantiation_regular in H7; mydestr. listctx_set_simpl.
  rewrite subst_commute_value; auto; basic_typing_solver3; set_solver.
Qed.

Lemma instantiation_app_spec: forall Γv1 Γv2 Γ,
    instantiation Γ (Γv1 ++ Γv2) <->
      ∃ Γ1 Γ2, Γ = Γ1 ++ Γ2 /\ ok Γ /\ instantiation Γ1 Γv1 /\ instantiation Γ2 Γv2 .
Proof.
  induction Γv1; split; simpl; intros.
  - exists [], Γ. repeat split; simpl; auto; instantiation_regular_solver.
  - mydestr; subst. invclear H1. auto.
  - invclear H. apply IHΓv1 in H5; mydestr.
    exists ((x, T) :: x0), x1. subst. repeat split; auto.
    + rewrite ok_pre_destruct; split; auto.
    + constructor; listctx_set_solver.
  - mydestr; subst. invclear H1. listctx_set_simpl.
    constructor; auto; listctx_set_simpl.
    rewrite IHΓv1. exists c, x0. repeat split; auto.
Qed.

Ltac instantiation_regular_simp :=
  repeat match goal with
    | [H: instantiation _ _ |- _ ∉ _ ] => apply instantiation_regular in H; mydestr
    end.

Lemma instantiation_app_spec': forall Γ1 Γ2 Γv,
    instantiation (Γ1 ++ Γ2) Γv <->
      ∃ Γv1 Γv2, Γv = Γv1 ++ Γv2 /\ ok Γv /\ instantiation Γ1 Γv1 /\ instantiation Γ2 Γv2 .
Proof.
  induction Γ1; split; simpl; intros.
  - exists [], Γv. repeat split; simpl; auto; instantiation_regular_solver.
  - mydestr; subst. invclear H1. auto.
  - invclear H. apply IHΓ1 in H5; mydestr.
    exists ((x, v) :: x0), x1. subst. repeat split; auto.
    + rewrite ok_pre_destruct; split; auto.
      instantiation_regular_simp. listctx_set_simpl. set_solver.
    + constructor; listctx_set_solver.
  - mydestr; subst. invclear H1. listctx_set_simpl.
    constructor; auto; listctx_set_simpl. instantiation_regular_simp. set_solver.
    rewrite IHΓ1. exists e, x0. repeat split; auto.
Qed.

Lemma tm_msubst_swap_hd_tl: forall Γv Γ Γv',
    instantiation Γ (Γv ++ Γv') -> ∀ e, tm_msubst (Γv ++ Γv') e = tm_msubst (Γv' ++ Γv) e.
Proof.
  induction Γv; intros.
  - listctx_set_simpl.
  - invclear H. rewrite instantiation_app_spec in H5; mydestr; subst.
    listctx_set_simpl. simpl.
    rewrite IHΓv with (Γ := (x0 ++ x1)); auto.
    rewrite tm_msubst_mid_subst with (Γ := (x1 ++ (x, T) :: x0)); eauto.
    + rewrite instantiation_app_spec. exists x1, ((x, T) :: x0). repeat split; auto.
      apply ok_mid_insert; split; listctx_set_solver5.
      constructor; auto; listctx_set_solver5.
    + basic_typing_solver3.
    + rewrite instantiation_app_spec. exists x0, x1. split; auto.
Qed.

Lemma msubst_preserves_body_tm: forall Γ Γv e,
    instantiation Γ Γv -> body e -> body (tm_msubst Γv e).
Proof.
  intros. induction H; simpl; auto.
  erewrite <- msubst_subst_commute_tm; eauto.
  apply subst_body_tm; auto; basic_typing_solver3.
  - instantiation_regular_solver.
  - basic_typing_solver3.
Qed.

Lemma termRraw_swap: forall e e' Γ1 Γ2, termRraw (Γ1 ++ Γ2) e e' -> termRraw (Γ2 ++ Γ1) e e'.
Proof.
  unfold termRraw. intros.
  apply instantiation_app_spec' in H0; mydestr; subst.
  assert (instantiation (Γ2 ++ Γ1) (x ++ x0)).
  { apply instantiation_app_spec'. exists x, x0. repeat split; auto. }
  erewrite tm_msubst_swap_hd_tl; eauto.
  erewrite tm_msubst_swap_hd_tl in H1; eauto.
  apply H; auto.
  rewrite instantiation_app_spec'. exists x0, x. repeat split; auto.
  listctx_set_solver5.
Qed.

Lemma termR_swap: forall e e' Γ1 Γ2 T, e <-<{ Γ1 ++ Γ2; T} e' <-> e <-<{ Γ2 ++ Γ1; T} e'.
Proof.
  split; intros; invclear H; constructor; auto; basic_typing_solver4; apply termRraw_swap; auto.
Qed.

Lemma termR_elete: forall γ Tx T e_x e_x' e e' (x: atom),
    e_x <-<{γ; Tx} e_x' -> e <-<{γ ++ [(x, Tx)]; T} e' ->
    (tlete e_x (x \t\ e)) <-<{γ; T} (tlete e_x' (x \t\ e')).
Proof.
    intros.
    assert (ok (γ ++ [(x, Tx)])) as HH. invclear H0. basic_typing_solver.
    invclear H. invclear H0. repeat split; auto.
  - auto_exists_L; intros. rewrite subst_as_close_open_tm; try basic_typing_solver.
    apply basic_has_type_renaming; eauto;  basic_typing_solver3.
  - auto_exists_L; intros. rewrite subst_as_close_open_tm; try basic_typing_solver.
    apply basic_has_type_renaming; eauto;  basic_typing_solver3.
  - unfold termRraw. intros Γv u Hi. intros. msubst_simpl.
    rewrite lete_step_spec in H0; simpl; mydestr.
    rewrite lete_step_spec; simpl.
    split.
    { eapply msubst_preserves_body_tm; eauto.
      auto_exists_L; intros. rewrite subst_as_close_open_tm; try basic_typing_solver3.
      apply subst_lc_tm; auto. }
    exists x0. split; auto.
    setoid_rewrite <- instantiation_implies_close_msubst in H7; eauto; basic_typing_solver3.
    setoid_rewrite <- instantiation_implies_close_msubst; eauto; basic_typing_solver3.
    setoid_rewrite subst_as_close_open_tm in H7; basic_typing_solver3.
    setoid_rewrite subst_as_close_open_tm; basic_typing_solver3.
    + specialize (H5 (Γv ++ [(x, x0)]) u).
      assert ([] ⊢t (tm_msubst Γv e_x ) ⋮t Tx) by (eapply msubst_preserves_typing_tm; eauto).
      assert ([] ⊢t x0 ⋮v Tx) by basic_typing_solver3.
      assert (instantiation (γ ++ [(x, Tx)]) (Γv ++ [(x, x0)])).
      { rewrite instantiation_app_spec. exists γ, [(x, Tx)]; repeat split; auto.
        repeat constructor; auto; try fast_set_solver. }
      rewrite tm_msubst_swap_hd_tl with (Γ := (γ ++ [(x, Tx)])) in H5; auto; simpl in H5.
      rewrite tm_msubst_swap_hd_tl with (Γ := (γ ++ [(x, Tx)])) in H5; auto; simpl in H5.
      rewrite <- msubst_subst_commute_tm with (Γ := γ) in H5; auto; basic_typing_solver3; try instantiation_regular_solver.
      rewrite <- msubst_subst_commute_tm with (Γ := γ) in H5; auto; basic_typing_solver3; try instantiation_regular_solver.
    + eapply instantiation_implies_msubst_lc; eauto.
    + eapply instantiation_implies_msubst_lc; eauto.
Qed.

Ltac termR_solver :=
  repeat (match goal with
          | [H: termRraw [] ?e ?e' |- ?e' ↪* _ ] =>
              assert ((forall (v: value), e ↪* v -> e' ↪* v)); auto;
              eapply termRraw_emp; eauto; try basic_typing_solver3
          | [|- (mk_app _ _) <-<{ _; _} (mk_app _ _)] => eapply mk_app_perserve_termR; eauto
          | [H: ?e <-<{ ?a ++ ?b; ?T} ?e' |- ?e <-<{ ?b ++ ?a; ?T} ?e'] => rewrite termR_swap; eauto
          | [H: ?e <-<{ (?x, ?t) :: ?b; ?T} ?e' |- ?e <-<{ ?b ++ [(?x, ?t)]; ?T} ?e'] => rewrite termR_swap; eauto
          end || termR_solver1).
