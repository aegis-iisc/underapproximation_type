Set Warnings "-notation-overridden,-parsing".
From PLF Require Import Maps.
From PLF Require Import CoreLangSimp.
From PLF Require Import NormalTypeSystemSimp.
From PLF Require Import LinearContext.
From PLF Require Import RfTypeDef.
From PLF Require Import TypeClosedSimp.
From PLF Require Import TermOrdering.
From PLF Require Import DenotationSimp.
From PLF Require Import WellFormedSimp.
From Coq Require Import Logic.FunctionalExtensionality.
From Coq Require Import Logic.ClassicalFacts.
From Coq Require Import Lists.List.
From Coq Require Import FunInd.
From Coq Require Import Recdef.

Import CoreLangSimp.
Import NormalTypeSystemSimp.
Import LinearContext.
Import RfTypeDef.
Import TypeClosedSimp.
Import DenotationSimp.
Import WellFormedSimp.
Import ListNotations.

Global Hint Constructors well_formed_type: core.

Lemma tmR_in_ctx_id_eq_c: forall st Gamma (id: string) c,
    tmR_in_ctx_aux st Gamma (mk_eq_constant c) id ->
    (forall e tau, tmR_in_ctx_aux st Gamma tau e <-> tmR_in_ctx_aux st Gamma tau (subst id c e)).
Admitted.

Lemma tmR_in_ctx_state_implies_subst: forall (st: nstate) a (c_a: constant) Gamma tau,
    st a = Some (tvalue c_a) ->
    l_find_right_most Gamma a = None ->
    (forall e, tmR_in_ctx_aux st Gamma tau e <-> tmR_in_ctx_aux st Gamma tau ([a := c_a] e)).
Admitted.

Lemma eta1: forall x1 x T e x2 (c_x:constant) x0,
    x1<> x2 -> ~ x1 \FVtm c_x ->
    (tlete x1 (vlam x T e) (tlete x2 c_x (tletapp x0 x1 x2 x0))) <=< (tlete x c_x e).
Admitted.

(* Assume there is no dup in the context to simplify the proof. *)
Lemma tmR_in_ctx_preserve_oarr: forall Gamma st x (tau_x: overbasety) e (tau: underty),
    tmR_in_ctx_aux st (Gamma <l> x :l: Oty tau_x) tau e ->
    tmR_in_ctx_aux st Gamma (x o: tau_x o--> tau) (vlam x (o\_ tau_x _/) e).
Proof with eauto.
  intro Gamma.
  induction Gamma; simpl; intros st x tau_x e tau HD.
  - setoid_rewrite app_nil_l in HD. inversion HD; subst. constructor... constructor... constructor...
    split.
    + simpl. constructor... constructor... apply tmR_in_ctx_aux_implies_has_type in HD...
    + intros c_x Hc_xD e3 Happ. inversion Happ; subst. simpl.
      eapply step_preserve_under_denotation... apply eta1...
      assert (tmR_in_ctx_aux (x |-> c_x; st) [] tau (tlete x c_x e)) as HH...
      inversion HH; subst. inversion H1...
  - destruct a as (a & tau_a).
    assert (type_ctx_no_dup ((a, tau_a) :: Gamma <l> x :l: tau_x)) as Hnodup...
    inversion HD; subst.
    + constructor... apply l_find_right_most_weak in H3. destruct H3...
      intros c_x Hc_xD.
      eapply step_preserve_ctx_denotation. apply eta_lete_const_to_subst.
      simpl... destruct (eqb_spec a x)... { exfalso. eapply type_ctx_no_dup_fst_last_diff_name... }
      eapply step_preserve_ctx_denotation... apply eta_lete_const_to_subst_in_lam...
      (* eapply IHGamma... *)
      (* apply type_ctx_no_dup_ctx_sub with (Gamma1 := (a, Oty ({{v:T | phi}}))::nil)... *)
    + constructor... apply l_find_right_most_weak in H3. destruct H3...
      destruct H9 as (e_x_hat & He_x_hatD & HH).
      exists e_x_hat. split...
      intros e_x He_xD.
      (* intros c_x Hc_xE Hc_xT e_x He_xD. *)
      eapply step_preserve_ctx_denotation... eapply eta_closed_term_can_captured_by_lam...
      (* apply IHGamma... *)
      (* apply type_ctx_no_dup_ctx_sub with (Gamma1 := (a, Uty ([[v:T | phi]]))::nil)... *)
    + constructor... apply l_find_right_most_weak in H3. destruct H3...
      intros e_x He_xD.
      eapply step_preserve_ctx_denotation... eapply eta_closed_term_can_captured_by_lam...
      (* apply IHGamma... *)
      (* eapply type_ctx_no_dup_ctx_sub with (Gamma1 := (a, Uty (a0 o: {{v:T | phi}} o--> tau_b))::nil)... *)
    + constructor... apply l_find_right_most_weak in H3. destruct H3...
      intros e_x He_xD.
      eapply step_preserve_ctx_denotation... eapply eta_closed_term_can_captured_by_lam...
      (* apply IHGamma... *)
      (* eapply type_ctx_no_dup_ctx_sub with (Gamma1 := (a, Uty (t1 u--> t2))::nil)... *)
Qed.

(* meet operation, the trick here is encode the conjunction into the target language, via a poly equal operator.

  let x1 = e1 in
  let x2 = e2 in
  let x3 = x1 ==T x2 in
  match x3 with
  | true -> x2
  | false -> err

 *)
Lemma meet_of_two_terms_exists: forall e1 e2 T,
    empty |- e1 \Tin T -> empty |- e2 \Tin T -> (exists e3, (empty |- e3 \Tin T) /\ (forall c, e3 -->* c <-> e1 -->* c /\ e2 -->* c)).
Admitted.

Lemma meet_of_two_terms_implies_denotation: forall st tau e1 e2 e3,
    under_tmR_aux st tau e1 -> under_tmR_aux st tau e2 ->
    (forall c, e3 -->* c <-> e1 -->* c /\ e2 -->* c) -> under_tmR_aux st tau e3.
Admitted.

Global Hint Resolve meet_of_two_terms_implies_denotation: core.


Lemma eta2: forall e2 (c2: constant) x1 e1 x2 x,
    e2 -->* c2 ->
    (tlete x1 e1 (tlete x2 c2 (tletapp x x1 x2 x))) <-< (tlete x1 e1 (tlete x2 e2 (tletapp x x1 x2 x))).
Admitted.

Lemma under_tmR_aux_st_update: forall x (c_x: constant) st tau,
    (forall e, under_tmR_aux (x |-> (tvalue c_x); st) tau e <-> under_tmR_aux st (<u[ x |c-> c_x ]> tau) e).
Admitted.

 (* tmR_in_ctx_aux st ((a, {{v:T0 | phi0}}) :: Gamma) ([[v:T | phi]]) e2 *)


Lemma eta3: forall x1 a (e_a: tm) Ta e1 x2 e2 x,
    empty |- e_a \Tin Ta ->
        (tlete a e_a (tlete x1 e1 (tlete x2 e2 (tletapp x x1 x2 x))))
          <=< (tlete x1 (tlete a e_a e1) (tlete x2 (tlete a e_a e2) (tletapp x x1 x2 x))).
Admitted.

Global Hint Resolve tmR_has_type: core.

Lemma tmR_in_ctx_preserve_application: forall Gamma st x1 x2 x (e1 e2: tm) tau a T phi,
    x1 <> x2 -> ~ x1 \FVtm e2 ->
    tmR_in_ctx_aux st Gamma (a o: {{v: T | phi}} o--> tau) e1 ->
    tmR_in_ctx_aux st Gamma ([[v: T | phi]]) e2 ->
    (forall (c2: constant), (forall e', tmR_in_ctx_aux st Gamma ([[v: T | phi]]) e' -> e' -->* c2) ->
                       tmR_in_ctx_aux st Gamma (under_subst_c a c2 tau)
                                      (tlete x1 e1 (tlete x2 e2 (tletapp x x1 x2 x)))
    ).
Proof with eauto.
  intro Gamma.
  induction Gamma; simpl; intros st x1 x2 x e1 e2 tau a0 T phi Hx1x2 Hx1free Hv1D Hv2D c2 Hc2Prop.
  - assert (e2 -->* c2) as He2E...
    inversion Hv1D; subst. inversion Hv2D; subst. clear Hv1D Hv2D.
    inversion H; subst. inversion H0; subst. clear H H0.
    (* inversion H0; subst. clear H0. *)
    constructor... constructor...
    inversion H3; subst. destruct H0 as (Hv1T & HH).
    assert (under_tmR_aux (a0 |-> c2; st) tau (tlete x1 e1 (tlete x2 c2 (tletapp x x1 x2 x))))... apply HH... admit.
    eapply step_preserve_under_denotation... apply eta2...
    rewrite <- under_tmR_aux_st_update...
  - destruct a as (a & tau_a).
    assert (type_ctx_no_dup ((a, tau_a) :: Gamma)) as Hnodup...
    inversion Hv1D; subst.
    + constructor... inversion H3... inversion H5...
      intros c_x He_xD. inversion Hv2D; subst.
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma (a0 o: {{v:T | phi}} o--> tau) (tlete a c_x e1)) as HHv1...
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma ([[v:T | phi]]) (tlete a c_x e2)) as HHv2...
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma (<u[ a0 |c-> c2 ]> tau) (tlete x1 (tlete a c_x e1) (tlete x2 (tlete a c_x e2) (tletapp x x1 x2 x)))). eapply IHGamma... admit.
      eapply step_preserve_ctx_denotation... eapply eta3...
    + constructor... inversion H3... inversion H5...
      destruct H9 as (e_x_hat1 & He_x_hat1D & HH1).
      inversion Hv2D; subst.
      { destruct H14 as (e_x_hat2 & He_x_hat2D & HH2).
        destruct (meet_of_two_terms_exists e_x_hat1 e_x_hat2 T0) as (e_x_hat3 & HT3 & HE3)...
        - apply tmR_has_type in He_x_hat1D...
        - apply tmR_has_type in He_x_hat2D...
        - exists e_x_hat3... split... admit.
          intros e_x He_xD.
          assert (tmR_in_ctx_aux (a |-> e_x_hat1; st) Gamma (a0 o: {{v:T | phi}} o--> tau) (tlete a e_x e1)) as Hv1...
          assert (tmR_in_ctx_aux (a |-> e_x_hat2; st) Gamma ([[v:T | phi]]) (tlete a e_x e2)) as Hv2...
          assert (tmR_in_ctx_aux (a |-> e_x_hat3; st) Gamma (<u[ a0 |c-> c2 ]> tau)
                                 (tlete x1 (tlete a e_x e1) (tlete x2 (tlete a e_x e2) (tletapp x x1 x2 x))))... eapply IHGamma... admit. admit. admit.
          eapply step_preserve_ctx_denotation... eapply eta3...
      }
    + constructor... inversion H3... inversion H5...
      inversion Hv1D; subst. inversion Hv2D; subst.
      intros e_x He_xD.
      assert (tmR_in_ctx_aux st Gamma (a0 o: {{v:T | phi}} o--> tau) (tlete a e_x e1)) as Hv1...
      assert (tmR_in_ctx_aux st Gamma ([[v:T | phi]]) (tlete a e_x e2)) as Hv2...
      assert (tmR_in_ctx_aux st Gamma (<u[ a0 |c-> c2 ]> tau) (tlete x1 (tlete a e_x e1) (tlete x2 (tlete a e_x e2) (tletapp x x1 x2 x))))... eapply IHGamma... admit.
      eapply step_preserve_ctx_denotation... eapply eta3...
    + constructor... inversion H3... inversion H5...
      inversion Hv1D; subst. inversion Hv2D; subst.
      intros e_x He_xD.
      assert (tmR_in_ctx_aux st Gamma (a0 o: {{v:T | phi}} o--> tau) (tlete a e_x e1))...
      assert (tmR_in_ctx_aux st Gamma ([[v:T | phi]]) (tlete a e_x e2))...
      assert (tmR_in_ctx_aux st Gamma (<u[ a0 |c-> c2 ]> tau) (tlete x1 (tlete a e_x e1) (tlete x2 (tlete a e_x e2) (tletapp x x1 x2 x))))... eapply IHGamma... admit.
      eapply step_preserve_ctx_denotation... eapply eta3...
Admitted.


Lemma tmR_in_ctx_preserve_arrarr: forall Gamma st x (tau_x: underty) e (tau: underty),
    tmR_in_ctx_aux st (Gamma <l> x :l: Uty tau_x) tau e ->
    tmR_in_ctx_aux st Gamma (tau_x u--> tau) (vlam x (u\_ tau_x _/) e).
Proof with eauto.
  intro Gamma.
  induction Gamma; simpl; intros st x tau_x e tau HD.
  - setoid_rewrite app_nil_l in HD.
Admitted.

(* Lemma eta_closed_term_can_penetrate_letapp: forall a e_a Ta x v1 v2 y Ty, *)
(*     empty |- e_a \Tin Ta -> *)
(*             a <> y -> ~ y \FVtm e_a -> *)
(*             (tletapp x (vlam y Ty (tlete a e_a (tletapp x v1 y x))) v2 x) *)
(*               <=< (tlete a e_a (tletapp x v1 v2 x)). *)
(* Admitted. *)

(* Another version of the denotation definition; HACK: how to prove it?  *)
(* Lemma e_x_hat_exists: forall st (T: base_ty) (phi: refinement), *)
(*     exists e_x_hat, *)
(*       under_tmR_aux st ([[v:T | phi]]) e_x_hat /\ *)
(*       (forall (c_x : constant), empty |- c_x \Vin T -> (e_x_hat -->* c_x <-> phi st c_x)). *)
(* Admitted. *)

(* Lemma e_x_hat_minimal: forall st (T: base_ty) (phi: refinement) e_x_hat e_x, *)
(*     under_tmR_aux st ([[v:T | phi]]) e_x_hat -> *)
(*     under_tmR_aux st ([[v:T | phi]]) e_x -> *)
(*     (forall (c_x : constant), empty |- c_x \Vin T -> (e_x_hat -->* c_x <-> phi st c_x)) -> *)
(*     e_x_hat <-< e_x. *)
(* Admitted. *)

Lemma tmR_in_ctx_preserve_arrarr_application: forall Gamma st x (v1 v2: value) tau tau1,
    tmR_in_ctx_aux st Gamma (tau1 u--> tau) v1 ->
    tmR_in_ctx_aux st Gamma tau1 v2 ->
    tmR_in_ctx_aux st Gamma tau (tletapp x v1 v2 x).
Proof with eauto.
  intro Gamma.
  induction Gamma; simpl; intros st x v1 v2 tau tau_x Hv1D Hv2D.
  - inversion Hv1D; subst. inversion Hv2D; subst. clear Hv1D Hv2D. constructor... inversion H; subst. inversion H3; subst. clear H H3. inversion H0; subst. clear H0.
    destruct H2 as (Hv1T & HH). destruct (value_value_is_application x v1 v2) as (e3 & (He3app & He3E)).
    eapply HH with (e3:=e3) in H4... constructor... eapply step_preserve_under_denotation... destruct He3E...
  - destruct a as (a & tau_a).
    inversion Hv1D; subst.
    + constructor... { inversion H5; subst... } inversion Hv2D; subst.
      intros c_x He_xD.
      (* make HHv1 and HHv2 to value. *)
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma (tau_x u--> tau) ([a := c_x] v1)) as HHv1...
      { eapply step_preserve_ctx_denotation... apply eta_lete_const_to_subst. }
      assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma tau_x ([a := c_x] v2)) as HHv2...
      { eapply step_preserve_ctx_denotation... apply eta_lete_const_to_subst. }
      eapply step_preserve_ctx_denotation. apply eta_lete_const_to_subst. rewrite subst_letapp_penetrate.
      eapply IHGamma...
    + constructor... { inversion H5; subst... }
      destruct H9 as (e_x_hat & He_x_hatD & HH).
      exists e_x_hat. split...
      (* intros c_x Hc_xT Hc_xD e_x He_xD. *)
      (* assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma (tau_x u--> tau) (tlete a e_x v1))... *)
      (* inversion Hv2D; subst... *)
      (* destruct v2. admit. destruct c. admit. *)
Admitted.

Lemma eta4: forall x1 (v1: value) x2 (c2: constant) x,
    x1 <> x2 ->
      tlete x1 v1 (tlete x2 c2 (tletapp x x1 x2 x)) <-< tletapp x v1 c2 x.
Admitted.


Lemma tmR_in_ctx_preserve_oarr_c_application: forall Gamma st x (v1: value) (c2: constant) tau a T phi,
    tmR_in_ctx_aux st Gamma (a o: {{v: T | phi}} o--> tau) v1 ->
    tmR_in_ctx_aux st Gamma ([[v: T | phi]]) c2 ->
    tmR_in_ctx_aux st Gamma (under_subst_c a c2 tau) (tletapp x v1 c2 x).
Proof with eauto.
  intro Gamma; simpl; intros st x v1 c2 tau a0 T phi Hv1D Hv2D.
  destruct (exists_fresh_var_of_value c2) as (x1 & x2 & Hx1x2 & Hfree).
  eapply tmR_in_ctx_preserve_application with (x1:=x1) (x2:=x2) (x:=x) (e2:=c2) (c2:=c2) in Hv1D...
  eapply step_preserve_ctx_denotation... eapply eta4... admit.
Admitted.

Lemma tmR_in_ctx_preserve_oarr_var_application: forall Gamma st x (v1: value) (name2: string) tau a T phi,
    tmR_in_ctx_aux st Gamma (a o: {{v: T | phi}} o--> tau) v1 ->
    tmR_in_ctx_aux st Gamma ([[v: T | phi]]) name2 ->
    tmR_in_ctx_aux st Gamma (under_subst_id a name2 tau) (tletapp x v1 name2 x).
Proof with eauto.
  intro Gamma; simpl; intros st x v1 c2 tau a0 T phi Hv1D Hv2D.
  destruct (exists_fresh_var_of_value c2) as (x1 & x2 & Hx1x2 & Hfree).
Admitted.
(*   intro Gamma. *)
(*   induction Gamma; simpl; intros st x v1 c2 tau a0 T phi Hv1D Hv2D. *)
(*   - admit. *)
(*   - destruct a as (a & tau_a). *)
(*     inversion Hv1D; subst. *)
(*     + constructor... admit. admit. *)
(*     + constructor... admit. *)
(*       destruct H7 as (e_x_hat & He_x_hatD & HH). *)
(*       assert (forall c_x : constant, *)
(*                  phi st c_x -> *)
(*                  empty |- c_x \Vin T0 -> *)
(*                          forall e_x : tm, *)
(*                            under_tmR_aux st ([[v:T0 | phi0]]) e_x -> *)
(*                            tmR_in_ctx_aux (a |-> c_x; st) Gamma (a0 o: {{v:T | phi}} o--> tau) (tlete a e_x v1)). *)
(*       { intros... apply HH... admit. } clear HH. clear He_x_hatD e_x_hat. *)
(*       inversion Hv2D; subst. *)
(*       destruct H11 as (e_x_hat & He_x_hatD & HH). *)
(*       exists e_x_hat. split... *)
(*       intros c_x Hc_xD Hc_xT e_x He_xD. *)
(*       assert (tmR_in_ctx_aux (a |-> c_x; st) Gamma ([[v:T | phi]]) (tlete a e_x c2))... clear HH. *)
(* Admitted. *)

Lemma tmR_in_ctx_preserve_matchb_true: forall Gamma st (v: value) e1 e2 tau,
    type_ctx_no_dup Gamma ->
    tmR_in_ctx_aux st Gamma (mk_eq_constant true) v ->
    tmR_in_ctx_aux st Gamma tau e1 ->
    tmR_in_ctx_aux st Gamma tau (tmatchb v e1 e2).
Proof with eauto.
  intros Gamma st v e1 e2 tau Hnodup Hv He1.
  assert ((exists n : bool, v = n) \/ (exists name : string, v = name)) as HH. apply tmR_in_ctx_aux_implies_has_type in Hv... inversion Hv; subst. apply bool_value_cid_exists in H1...
  destruct HH.
  - destruct H as (b & Hb); subst. apply mk_eq_constant_is_itsefl_in_ctx in Hv. rewrite Hv.
    eapply step_preserve_ctx_denotation... apply eta_matchb_true...
  - destruct H as (id & Hid); subst. rewrite tmR_in_ctx_id_eq_c... simpl. rewrite eqb_refl.
    apply step_preserve_ctx_denotation with (e:= ([id := true] e1))... apply eta_matchb_true...
    rewrite <- tmR_in_ctx_id_eq_c...
Qed.


Lemma tmR_in_ctx_preserve_matchb_false: forall st Gamma (v: value) e1 e2 tau,
    type_ctx_no_dup Gamma ->
    tmR_in_ctx_aux st Gamma (mk_eq_constant false) v ->
    tmR_in_ctx_aux st Gamma tau e2 ->
    tmR_in_ctx_aux st Gamma tau (tmatchb v e1 e2).
Proof with eauto.
  intros st Gamma v e1 e2 tau Hnodup Hv He1.
  assert ((exists n : bool, v = n) \/ (exists name : string, v = name)) as HH. apply tmR_in_ctx_aux_implies_has_type in Hv... inversion Hv; subst. apply bool_value_cid_exists in H1...
  destruct HH.
  - destruct H as (b & Hb); subst. apply mk_eq_constant_is_itsefl_in_ctx in Hv. rewrite Hv.
    eapply step_preserve_ctx_denotation... apply eta_matchb_false...
  - destruct H as (id & Hid); subst. rewrite tmR_in_ctx_id_eq_c... simpl. rewrite eqb_refl.
    apply step_preserve_ctx_denotation with (e:= ([id := false] e2))... apply eta_matchb_false...
    rewrite <- tmR_in_ctx_id_eq_c...
Qed.

