Set Warnings "-notation-overridden,-parsing".
From PLF Require Import Maps.
From PLF Require Import CoreLangSimp.
From PLF Require Import NormalTypeSystemSimp.
From PLF Require Import LinearContext.
From PLF Require Import RfTypeDef.
From PLF Require Import TypeClosedSimp.
From PLF Require Import DenotationSimp.
From PLF Require Import WellFormedSimp.
From PLF Require Import DenotationSpecsSimp.
From Coq Require Import Logic.FunctionalExtensionality.
From Coq Require Import Logic.ClassicalFacts.
From Coq Require Import Lists.List.

Import CoreLangSimp.
Import LinearContext.
Import TypeClosedSimp.
Import DenotationSimp.
Import WellFormedSimp.
Import DenotationSpecsSimp.
Import ListNotations.

Lemma tmR_nst_no_free_implies_eq: forall st x e_x_hat (tau: underty),
    ~ appear_free_in_underty x tau -> (forall e, tmR_aux (x |-> e_x_hat; st) tau e <-> tmR_aux st tau e).
Admitted.

Global Hint Rewrite tmR_nst_no_free_implies_eq: core.
Global Hint Resolve tmR_has_type: core.

Lemma lete_ctx_inv_implies_safe_dropping_1_to_1: forall Gamma st x tau_x tau,
    ~ appear_free_in_underty x tau ->
    ctx_inv st (Gamma ++ ((x, Uty tau_x)::nil)) ->
    (forall e, tmR_in_ctx_aux st (Gamma ++ ((x, Uty tau_x)::nil)) tau e ->
          (forall e_x, tmR_in_ctx_aux st Gamma tau_x e_x -> tmR_in_ctx_aux st Gamma tau (tlete x e_x e))).
Proof with eauto.
  intro Gamma. induction Gamma; simpl; intros st x tau_x tau Hfree Hinv e HeD e_x He_xD.
  - constructor... inversion He_xD; subst. inversion HeD; subst.
    + destruct H10 as (e_x_hat & He_x_hatD & HH).
      assert (tmR_in_ctx_aux (x |-> e_x_hat; st) [] tau (tlete x e_x e)) as HD... inversion HD; subst...
      rewrite <- tmR_nst_no_free_implies_eq...
    + assert (tmR_in_ctx_aux st [] tau (tlete x e_x e)) as HD... inversion HD; subst...
    + assert (tmR_in_ctx_aux st [] tau (tlete x e_x e)) as HD... inversion HD; subst...
  - destruct a as (a & tau_a).
    inversion HeD; subst.
    + constructor... admit.
      intros c_x Hc_xD.
      assert (tmR_in_ctx_aux (a |-> c_x; st) (Gamma ++ ((x, Uty tau_x)::nil)) tau (tlete a c_x e))...
      inversion He_xD; subst...
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma tau_x (tlete a c_x e_x))...
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma tau (tlete x e_x (tlete a c_x e))). eapply IHGamma... admit.
      admit.
    + constructor... admit.
      destruct H9 as (e_x_hat1 & He_x_hatD1 & HH1).
      inversion He_xD; subst...
      destruct H14 as (e_x_hat2 & He_x_hatD2 & HH2).
      destruct (meet_of_two_terms_exists e_x_hat1 e_x_hat2 T) as (e_x_hat3 & HT3 & HE3)... apply tmR_has_type in He_x_hatD1... apply tmR_has_type in He_x_hatD2...
      exists e_x_hat3. split... admit.
      intros e_x' He_xD'.
      assert (tmR_in_ctx_aux (a |-> e_x_hat1; st) (Gamma ++ ((x, Uty tau_x)::nil)) tau (tlete a e_x' e)). apply HH1...
      assert (tmR_in_ctx_aux (a |-> e_x_hat2; st) Gamma tau_x (tlete a e_x' e_x)). apply HH2...
      assert (tmR_in_ctx_aux (a |-> e_x_hat3; st) Gamma tau (tlete x (tlete a e_x' e_x) (tlete a e_x' e)))... eapply IHGamma with (tau_x:= tau_x)... admit. admit. admit. admit.
    + constructor... admit.
      inversion He_xD; subst.
      intros e_x' He_xD'.
      assert (tmR_in_ctx_aux st (Gamma ++ ((x, Uty tau_x)::nil)) tau (tlete a e_x' e))...
      assert (tmR_in_ctx_aux st Gamma tau_x (tlete a e_x' e_x))...
      assert (tmR_in_ctx_aux st Gamma tau (tlete x (tlete a e_x' e_x) (tlete a e_x' e)))... eapply IHGamma... admit.
      admit.
    + constructor... admit.
      inversion He_xD; subst.
      intros e_x' He_xD'.
      assert (tmR_in_ctx_aux st (Gamma ++ ((x, Uty tau_x)::nil)) tau (tlete a e_x' e))...
      assert (tmR_in_ctx_aux st Gamma tau_x (tlete a e_x' e_x))...
      assert (tmR_in_ctx_aux st Gamma tau (tlete x (tlete a e_x' e_x) (tlete a e_x' e)))... eapply IHGamma... admit.
      admit.
Admitted.




Lemma tletbiop_ctx_inv_implies_safe_dropping_1_to_1: forall Gamma x tau,
    (forall e op (v1 v2: cid),
        ctx_inv empty (Gamma ++ ((x, Uty (mk_op_retty_from_cids op v1 v2))::nil)) ->
        tmR_in_ctx_all_st (Gamma ++ ((x, Uty (mk_op_retty_from_cids op v1 v2))::nil)) tau e ->
        tmR_in_ctx_all_st (Gamma <l> x :l: ((mk_op_retty_from_cids op v1 v2))) tau e ->
        tmR_in_ctx_all_st Gamma tau (tletbiop x op v1 v2 e)).
Admitted.

Lemma tletapp_oarr_ctx_inv_implies_safe_dropping_1_to_1: forall Gamma x tau_x tau,
    (forall e (v1: value) (v2: cid) a T phi1,
        tmR_in_ctx_all_st Gamma (a o: {{v: T | phi1}} o--> tau_x) v1 ->
        tmR_in_ctx_all_st Gamma ([[v: T | phi1]]) v2 ->
        ctx_inv empty (Gamma ++ ((x, Uty (under_subst_cid a v2 tau_x))::nil)) ->
        tmR_in_ctx_all_st (Gamma ++ ((x, Uty (under_subst_cid a v2 tau_x))::nil)) tau e ->
        tmR_in_ctx_all_st Gamma tau (tletapp x v1 v2 e)).
Admitted.

Lemma tletapp_arrarr_ctx_inv_implies_safe_dropping_1_to_1: forall Gamma x tau_x tau,
    ~ appear_free_in_underty x tau_x ->
    ctx_inv empty (Gamma ++ ((x, Uty tau_x)::nil)) ->
    (forall e, tmR_in_ctx_all_st (Gamma ++ ((x, Uty tau_x)::nil)) tau e ->
          (forall (v1 v2: value) t1,
              tmR_in_ctx_all_st Gamma (t1 u--> tau_x) v1 ->
              tmR_in_ctx_all_st Gamma t1 v2 ->
              tmR_in_ctx_all_st Gamma tau (tletapp x v1 v2 e))).
Admitted.
