(** * IndProp: Inductively Defined Propositions *)

Set Warnings "-notation-overridden,-parsing,-deprecated-hint-without-locality".
From LF Require Export Logic.

(* ################################################################# *)
(** * Inductively Defined Propositions *)

(** In the [Logic] chapter, we looked at several ways of writing
    propositions, including conjunction, disjunction, and existential
    quantification.

    In this chapter, we bring yet another new tool into the mix:
    _inductively defined propositions_.

    To begin, some examples... *)

(* ================================================================= *)
(** ** Example: The Collatz Conjecture *)

(** The _Collatz Conjecture_ is a famous open problem in number
    theory.

    Its statement is quite simple.  First, we define a function [f]
    on numbers, as follows: *)

Fixpoint div2 (n : nat) :=
  match n with
    0 => 0
  | 1 => 0
  | S (S n) => S (div2 n)
  end.

Definition f (n : nat) :=
  if even n then div2 n
  else (3 * n) + 1.

(** Next, we look at what happens when we repeatedly apply [f] to
    some given starting number.  For example, [f 12] is [6], and [f
    6] is [3], so by repeatedly applying [f] we get the sequence
    [12, 6, 3, 10, 5, 16, 8, 4, 2, 1].

    Similarly, if we start with [19], we get the longer sequence
    [19, 58, 29, 88, 44, 22, 11, 34, 17, 52, 26, 13, 40, 20, 10, 5,
    16, 8, 4, 2, 1].

    Both of these sequences eventually reach [1].  The question
    posed by Collatz was: Is the sequence starting from _any_
    natural number guaranteed to reach [1] eventually? *)

(** To formalize this question in Coq, we might try to define a
    recursive _function_ that calculates the total number of steps
    that it takes for such a sequence to reach [1]. *)

Fail Fixpoint reaches_1_in (n : nat) :=
  if n =? 1 then true
  else 1 + reaches_1_in (f n).

(** This definition is rejected by Coq's termination checker, since
    the argument to the recursive call, [f n], is not "obviously
    smaller" than [n].

    Indeed, this isn't just a pointless limitation: functions in Coq
    are required to be total, to ensure logical consistency.

    Moreover, we can't fix it by devising a more clever termination
    checker: deciding whether this particular function is total
    would be equivalent to settling the Collatz conjecture! *)

(** Fortunately, there is another way to do it: We can express the
    concept "reaches [1] eventually" as an _inductively defined
    property_ of numbers: *)

Inductive Collatz_holds_for : nat -> Prop :=
  | Chf_done : Collatz_holds_for 1
  | Chf_more (n : nat) : Collatz_holds_for (f n) -> Collatz_holds_for n.

(** What we've done here is to use Coq's [Inductive] definition
    mechanism to characterize the property "Collatz holds for..." by
    stating two different ways in which it can hold: (1) Collatz holds
    for [1] and (2) if Collatz holds for [f n] then it holds for
    [n]. *)

(** For particular numbers, we can now argue that the Collatz sequence
    reaches [1] like this (again, we'll go through the details of how
    it works a bit later in the chapter): *)

Example Collatz_holds_for_12 : Collatz_holds_for 12.
Proof.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_more. unfold f. simpl.
  apply Chf_done.  Qed.

(** The Collatz conjecture then states that the sequence beginning
    from _any_ number reaches [1]: *)

Conjecture collatz : forall n, Collatz_holds_for n.


(** If you succeed in proving this conjecture, you've got a bright
    future as a number theorist!  But don't spend too long on it --
    it's been open since 1937. *)

(* ================================================================= *)
(** ** Example: Ordering *)

(** A binary _relation_ on a set [X] is a family of propositions
    parameterized by two elements of [X] -- i.e., a proposition
    about pairs of elements of [X].  *)

(** For example, one familiar binary relation on [nat] is [le], the
    less-than-or-equal-to relation.  We've already seen how to define
    it as a boolean computation.  Here is a "direct" propositional
    definition. *)

Module LePlayground.

(** The following definition says that there are two ways to
    show that one number is less than or equal to another: either
    observe that they are the same number, or, if the second has the
    form [S m], give evidence that the first is less than or equal to
    [m]. *)

Inductive le : nat -> nat -> Prop :=
  | le_n (n : nat)   : le n n
  | le_S (n m : nat) : le n m -> le n (S m).

Notation "n <= m" := (le n m) (at level 70).

Example le_3_5 : 3 <= 5.
Proof.
  apply le_S. apply le_S. apply le_n. Qed.

End LePlayground.

Module LePlayground1.

(** (By "reserving" the notation before defining the [Inductive], we
    can use it in the definition.) *)

Reserved Notation "n <= m" (at level 70).

Inductive le : nat -> nat -> Prop :=
  | le_n (n : nat)   : n <= n
  | le_S (n m : nat) : n <= m -> n <= (S m)

  where "n <= m" := (le n m).

End LePlayground1.

(* ================================================================= *)
(** ** Example: Transitive Closure *)

(** As another example, the _transitive closure_ of a relation [R]
    is the smallest relation that contains [R] and that is
    transitive.  *)

Inductive clos_trans {X: Type} (R: X->X->Prop) : X->X->Prop :=
  | t_step (x y : X) :
      R x y ->
      clos_trans R x y
  | t_trans (x y z : X) :
      clos_trans R x y ->
      clos_trans R y z ->
      clos_trans R x z.

(** For example, suppose we define a "parent of" relation on a group
    of people... *)

Inductive Person : Type := Sage | Cleo | Ridley | Moss.

Inductive parent_of : Person -> Person -> Prop :=
  po_SC : parent_of Sage Cleo
| po_SR : parent_of Sage Ridley
| po_CM : parent_of Cleo Moss.

(** Then we can define "ancestor of" as its transitive closure: *)

Definition ancestor_of : Person -> Person -> Prop :=
  clos_trans parent_of.

Example ancestor_of1 : ancestor_of Sage Moss.
Proof.
  unfold ancestor_of. apply t_trans with Cleo.
  - apply t_step. apply po_SC.
  - apply t_step. apply po_CM. Qed.

(** **** Exercise: 1 star, standard, optional (close_refl_trans)

    How would you modify this definition so that it defines _reflexive
    and_ transitive closure?  How about reflexive, symmetric, and
    transitive closure? *)

(* FILL IN HERE

    [] *)

Inductive close_refl_trans {X: Type} (R: X->X->Prop) : X->X->Prop :=
  | rst_step (x y : X) :
      R x y ->
      close_refl_trans R x y
  | rst_refl (x: X) : R x x -> close_refl_trans R x x
  | rst_symm (x y: X) : R x y -> close_refl_trans R y x
  | rst_trans (x y z : X) :
      close_refl_trans R x y ->
      close_refl_trans R y z ->
      close_refl_trans R x z.

(* ================================================================= *)
(** ** Example: Permutations *)

(** The familiar mathematical concept of _permutation_ also has an
    elegant formulation as an inductive relation.  For simplicity,
    let's focus on permutations of lists with exactly three
    elements. *)

Inductive Perm3 {X : Type} : list X -> list X -> Prop :=
  | perm3_swap12 (a b c : X) :
      Perm3 [a;b;c] [b;a;c]
  | perm3_swap23 (a b c : X) :
      Perm3 [a;b;c] [a;c;b]
  | perm3_trans (l1 l2 l3 : list X) :
      Perm3 l1 l2 -> Perm3 l2 l3 -> Perm3 l1 l3.

(** This definition says:
      - If [l2] can be obtained from [l1] by swapping the first and
        second elements, then [l2] is a permutation of [l1].
      - If [l2] can be obtained from [l1] by swapping the second and
        third elements, then [l2] is a permutation of [l1].
      - If [l2] is a permutation of [l1] and [l3] is a permutation of
        [l2], then [l3] is a permutation of [l1]. *)

(** **** Exercise: 1 star, standard, optional (perm)

    According to this definition, is [[1;2;3]] a permutation of
    [[3;2;1]]?  Is [[1;2;3]] a permutation of itself? *)

(* FILL IN HERE
Using symmetry and transitivity we can prove [1;2;3] is a permutation of itself
    [] *)

Example Perm3_example1 : Perm3 [1;2;3] [2;3;1].
Proof.
  apply perm3_trans with [2;1;3].
  - apply perm3_swap12.
  - apply perm3_swap23.   Qed.

(* ================================================================= *)
(** ** Example: Evenness (yet again) *)

(** We've already seen two ways of stating a proposition that a number
    [n] is even: We can say

      (1) [even n = true], or

      (2) [exists k, n = double k].

    A third possibility, which we'll use as a running example for the
    rest of this chapter, is to say that [n] is even if we can
    _establish_ its evenness from the following rules:

       - The number [0] is even.
       - If [n] is even, then [S (S n)] is even. *)

(** (Defining evenness in this way may seem a bit confusing,
    since we have already seen another perfectly good way of doing
    it -- "[n] is even if it is equal to the result of doubling some
    number". It makes a convenient running example because it is
    simple and compact, but we will see more compelling examples in
    future chapters.) *)

(** To illustrate how this new definition of evenness works,
    let's imagine using it to show that [4] is even. First, we give
    the rules names for easy reference:
       - Rule [ev_0]: The number [0] is even.
       - Rule [ev_SS]: If [n] is even, then [S (S n)] is even.

    Now, by rule [ev_SS], it suffices to show that [2] is even. This,
    in turn, is again guaranteed by rule [ev_SS], as long as we can
    show that [0] is even. But this last fact follows directly from
    the [ev_0] rule. *)

(** We can translate the informal definition of evenness from above
    into a formal [Inductive] declaration, where each "way that a
    number can be even" corresponds to a separate constructor: *)

Inductive ev : nat -> Prop :=
  | ev_0                       : ev 0
  | ev_SS (n : nat) (H : ev n) : ev (S (S n)).

(** This definition is interestingly different from previous uses of
    [Inductive].  For one thing, we are defining not a [Type] (like
    [nat]) or a function yielding a [Type] (like [list]), but rather a
    function from [nat] to [Prop] -- that is, a property of numbers.
    But what is really new is that, because the [nat] argument of [ev]
    appears to the _right_ of the colon on the first line, it is
    allowed to take _different_ values in the types of different
    constructors: [0] in the type of [ev_0] and [S (S n)] in the type
    of [ev_SS].  Accordingly, the type of each constructor must be
    specified explicitly (after a colon), and each constructor's type
    must have the form [ev n] for some natural number [n].

    In contrast, recall the definition of [list]:

    Inductive list (X:Type) : Type :=
      | nil
      | cons (x : X) (l : list X).

    or equivalently:

    Inductive list (X:Type) : Type :=
      | nil                       : list X
      | cons (x : X) (l : list X) : list X.

   This definition introduces the [X] parameter _globally_, to the
   _left_ of the colon, forcing the result of [nil] and [cons] to be
   the same type (i.e., [list X]).  But if we had tried to bring [nat]
   to the left of the colon in defining [ev], we would have seen an
   error: *)

Fail Inductive wrong_ev (n : nat) : Prop :=
  | wrong_ev_0 : wrong_ev 0
  | wrong_ev_SS (H: wrong_ev n) : wrong_ev (S (S n)).
(* ===> Error: Last occurrence of "[wrong_ev]" must have "[n]" as 1st
        argument in "[wrong_ev 0]". *)

(** In an [Inductive] definition, an argument to the type constructor
    on the left of the colon is called a "parameter", whereas an
    argument on the right is called an "index" or "annotation."

    For example, in [Inductive list (X : Type) := ...], the [X] is a
    parameter, while in [Inductive ev : nat -> Prop := ...], the
    unnamed [nat] argument is an index. *)

(** We can think of this as defining a Coq property [ev : nat ->
    Prop], together with "evidence constructors" [ev_0 : ev 0] and
    [ev_SS : forall n, ev n -> ev (S (S n))]. *)

(** These evidence constructors can be thought of as "primitive
    evidence of evenness", and they can be used just like proven
    theorems.  In particular, we can use Coq's [apply] tactic with the
    constructor names to obtain evidence for [ev] of particular
    numbers... *)

Theorem ev_4 : ev 4.
Proof. apply ev_SS. apply ev_SS. apply ev_0. Qed.

(** ... or we can use function application syntax to combine several
    constructors: *)

Theorem ev_4' : ev 4.
Proof. apply (ev_SS 2 (ev_SS 0 ev_0)). Qed.

(** In this way, we can also prove theorems that have hypotheses
    involving [ev]. *)

Theorem ev_plus4 : forall n, ev n -> ev (4 + n).
Proof.
  intros n. simpl. intros Hn.  apply ev_SS. apply ev_SS. apply Hn.
Qed.

(** **** Exercise: 1 star, standard (ev_double) *)
Theorem ev_double : forall n,
  ev (double n).
Proof.
  induction n as [|n' IH].
  - simpl. apply ev_0.
  - simpl. apply ev_SS. apply IH.
Qed.
(** [] *)

(* ################################################################# *)
(** * Using Evidence in Proofs *)

(** Besides _constructing_ evidence that numbers are even, we can also
    _destruct_ such evidence, reasoning about how it could have been
    built.

    Defining [ev] with an [Inductive] declaration tells Coq not
    only that the constructors [ev_0] and [ev_SS] are valid ways to
    build evidence that some number is [ev], but also that these two
    constructors are the _only_ ways to build evidence that numbers
    are [ev]. *)

(** In other words, if someone gives us evidence [E] for the assertion
    [ev n], then we know that [E] must be one of two things:

      - [E] is [ev_0] (and [n] is [O]), or
      - [E] is [ev_SS n' E'] (and [n] is [S (S n')], where [E'] is
        evidence for [ev n']). *)

(** This suggests that it should be possible to analyze a
    hypothesis of the form [ev n] much as we do inductively defined
    data structures; in particular, it should be possible to argue by
    _case analysis_ or by _induction_ on such evidence.  Let's look at a
    few examples to see what this means in practice. *)

(* ================================================================= *)
(** ** Inversion on Evidence *)

(** Suppose we are proving some fact involving a number [n], and
    we are given [ev n] as a hypothesis.  We already know how to
    perform case analysis on [n] using [destruct] or [induction],
    generating separate subgoals for the case where [n = O] and the
    case where [n = S n'] for some [n'].  But for some proofs we may
    instead want to analyze the evidence for [ev n] _directly_.

    As a tool for such proofs, we can formalize the intuitive
    characterization that we gave above for evidence of [ev n], using
    [destruct]. *)

Theorem ev_inversion : forall (n : nat),
    ev n ->
    (n = 0) \/ (exists n', n = S (S n') /\ ev n').
Proof.
  intros n E.  destruct E as [ | n' E'] eqn:EE.
  - (* E = ev_0 : ev 0 *)
    left. reflexivity.
  - (* E = ev_SS n' E' : ev (S (S n')) *)
    right. exists n'. split. reflexivity. apply E'.
Qed.

(** Facts like this are often called "inversion lemmas" because they
    allow us to "invert" some given information to reason about all
    the different ways it could have been derived.

    Here, there are two ways to prove [ev n], and the inversion lemma
    makes this explicit. *)

(** We can use the inversion lemma that we proved above to help
    structure proofs: *)

Theorem evSS_ev : forall n, ev (S (S n)) -> ev n.
Proof.
  intros n H. apply ev_inversion in H.  destruct H as [H0|H1].
  - discriminate H0.
  - destruct H1 as [n' [Hnm Hev]]. injection Hnm as Heq.
    rewrite Heq. apply Hev.
Qed.

(** Note how the inversion lemma produces two subgoals, which
    correspond to the two ways of proving [ev].  The first subgoal is
    a contradiction that is discharged with [discriminate].  The
    second subgoal makes use of [injection] and [rewrite].

    Coq provides a handy tactic called [inversion] that factors out
    this common pattern, saving us the trouble of explicitly stating
    and proving an inversion lemma for every [Inductive] definition we
    make.

    Here, the [inversion] tactic can detect (1) that the first case,
    where [n = 0], does not apply and (2) that the [n'] that appears
    in the [ev_SS] case must be the same as [n].  It includes an
    "[as]" annotation similar to [destruct], allowing us to assign
    names rather than have Coq choose them. *)

Theorem evSS_ev' : forall n,
  ev (S (S n)) -> ev n.
Proof.
  intros n E.  inversion E as [| n' E' Heq].
  (* We are in the [E = ev_SS n' E'] case now. *)
  apply E'.
Qed.

(** The [inversion] tactic can apply the principle of explosion to
    "obviously contradictory" hypotheses involving inductively defined
    properties, something that takes a bit more work using our
    inversion lemma. Compare: *)

Theorem one_not_even : ~ ev 1.
Proof.
  intros H. apply ev_inversion in H.  destruct H as [ | [m [Hm _]]].
  - discriminate H.
  - discriminate Hm.
Qed.

Theorem one_not_even' : ~ ev 1.
Proof.
  intros H. inversion H. Qed.

(** **** Exercise: 1 star, standard (inversion_practice)

    Prove the following result using [inversion].  (For extra
    practice, you can also prove it using the inversion lemma.) *)

Theorem SSSSev__even : forall n,
  ev (S (S (S (S n)))) -> ev n.
Proof.
  intros n h.
  inversion h as [|n' E' Heq].
  inversion E' as [|n'' E'' Heq'].
  apply E''.
Qed.
(** [] *)

(** **** Exercise: 1 star, standard (ev5_nonsense)

    Prove the following result using [inversion]. *)

Theorem ev5_nonsense :
  ev 5 -> 2 + 2 = 9.
Proof.
  intro h.
  inversion h as [|n' E' Heq].
  inversion E' as [|n'' E'' Heq'].
  inversion E''.
Qed.
(** [] *)

(** The [inversion] tactic does quite a bit of work. For
    example, when applied to an equality assumption, it does the work
    of both [discriminate] and [injection]. In addition, it carries
    out the [intros] and [rewrite]s that are typically necessary in
    the case of [injection]. It can also be applied to analyze
    evidence for arbitrary inductively defined propositions, not just
    equality.  As examples, we'll use it to re-prove some theorems
    from chapter [Tactics].  (Here we are being a bit lazy by
    omitting the [as] clause from [inversion], thereby asking Coq to
    choose names for the variables and hypotheses that it introduces.) *)

Theorem inversion_ex1 : forall (n m o : nat),
  [n; m] = [o; o] -> [n] = [m].
Proof.
  intros n m o H. inversion H. reflexivity. Qed.

Theorem inversion_ex2 : forall (n : nat),
  S n = O -> 2 + 2 = 5.
Proof.
  intros n contra. inversion contra. Qed.

(** Here's how [inversion] works in general.
      - Suppose the name [H] refers to an assumption [P] in the
        current context, where [P] has been defined by an [Inductive]
        declaration.
      - Then, for each of the constructors of [P], [inversion H]
        generates a subgoal in which [H] has been replaced by the
        specific conditions under which this constructor could have
        been used to prove [P].
      - Some of these subgoals will be self-contradictory; [inversion]
        throws these away.
      - The ones that are left represent the cases that must be proved
        to establish the original goal.  For those, [inversion] adds
        to the proof context all equations that must hold of the
        arguments given to [P] -- e.g., [n' = n] in the proof of
        [evSS_ev]). *)

(** The [ev_double] exercise above shows that our new notion of
    evenness is implied by the two earlier ones (since, by
    [even_bool_prop] in chapter [Logic], we already know that
    those are equivalent to each other). To show that all three
    coincide, we just need the following lemma. *)

Lemma ev_Even_firsttry : forall n,
  ev n -> Even n.
Proof.
  (* WORKED IN CLASS *) unfold Even.

(** We could try to proceed by case analysis or induction on [n].  But
    since [ev] is mentioned in a premise, this strategy seems
    unpromising, because (as we've noted before) the induction
    hypothesis will talk about [n-1] (which is _not_ even!).  Thus, it
    seems better to first try [inversion] on the evidence for [ev].
    Indeed, the first case can be solved trivially. And we can
    seemingly make progress on the second case with a helper lemma. *)

  intros n E. inversion E as [EQ' | n' E' EQ'].
  - (* E = ev_0 *) exists 0. reflexivity.
  - (* E = ev_SS n' E'

    Unfortunately, the second case is harder.  We need to show [exists
    n0, S (S n') = double n0], but the only available assumption is
    [E'], which states that [ev n'] holds.  Since this isn't directly
    useful, it seems that we are stuck and that performing case
    analysis on [E] was a waste of time.

    If we look more closely at our second goal, however, we can see
    that something interesting happened: By performing case analysis
    on [E], we were able to reduce the original result to a similar
    one that involves a _different_ piece of evidence for [ev]: namely
    [E'].  More formally, we could finish our proof if we could show
    that

        exists k', n' = double k',

    which is the same as the original statement, but with [n'] instead
    of [n].  Indeed, it is not difficult to convince Coq that this
    intermediate result would suffice. *)
    assert (H: (exists k', n' = double k')
               -> (exists n0, S (S n') = double n0)).
        { intros [k' EQ'']. exists (S k'). simpl.
          rewrite <- EQ''. reflexivity. }
    apply H.

    (** Unfortunately, now we are stuck. To see this clearly, let's
        move [E'] back into the goal from the hypotheses. *)

    generalize dependent E'.

    (** Now it is obvious that we are trying to prove another instance
        of the same theorem we set out to prove -- only here we are
        talking about [n'] instead of [n]. *)
Abort.

(* ================================================================= *)
(** ** Induction on Evidence *)

(** If this story feels familiar, it is no coincidence: We
    encountered similar problems in the [Induction] chapter, when
    trying to use case analysis to prove results that required
    induction.  And once again the solution is... induction! *)

(** The behavior of [induction] on evidence is the same as its
    behavior on data: It causes Coq to generate one subgoal for each
    constructor that could have used to build that evidence, while
    providing an induction hypothesis for each recursive occurrence of
    the property in question.

    To prove that a property of [n] holds for all even numbers (i.e.,
    those for which [ev n] holds), we can use induction on [ev
    n]. This requires us to prove two things, corresponding to the two
    ways in which [ev n] could have been constructed. If it was
    constructed by [ev_0], then [n=0] and the property must hold of
    [0]. If it was constructed by [ev_SS], then the evidence of [ev n]
    is of the form [ev_SS n' E'], where [n = S (S n')] and [E'] is
    evidence for [ev n']. In this case, the inductive hypothesis says
    that the property we are trying to prove holds for [n']. *)

(** Let's try proving that lemma again: *)

Lemma ev_Even : forall n,
  ev n -> Even n.
Proof.
  intros n E.
  induction E as [|n' E' IH].
  - (* E = ev_0 *)
    unfold Even. exists 0. reflexivity.
  - (* E = ev_SS n' E'
       with IH : Even n' *)
    unfold Even in IH.
    destruct IH as [k Hk].
    rewrite Hk.
    unfold Even. exists (S k). simpl. reflexivity.
Qed.

(** Here, we can see that Coq produced an [IH] that corresponds
    to [E'], the single recursive occurrence of [ev] in its own
    definition.  Since [E'] mentions [n'], the induction hypothesis
    talks about [n'], as opposed to [n] or some other number. *)

(** The equivalence between the second and third definitions of
    evenness now follows. *)

Theorem ev_Even_iff : forall n,
  ev n <-> Even n.
Proof.
  intros n. split.
  - (* -> *) apply ev_Even.
  - (* <- *) unfold Even. intros [k Hk]. rewrite Hk. apply ev_double.
Qed.

(** As we will see in later chapters, induction on evidence is a
    recurring technique across many areas -- in particular for
    formalizing the semantics of programming languages. *)

(** The following exercises provide simple examples of this
    technique, to help you familiarize yourself with it. *)

(** **** Exercise: 2 stars, standard (ev_sum) *)
Theorem ev_sum : forall n m, ev n -> ev m -> ev (n + m).
Proof.
  intros n m.
  intros Hevn Hevm.
  induction Hevm as [|n' E IH].
  - rewrite add_0_r. apply Hevn.
  - rewrite add_n_plus_Sm.
    rewrite add_n_plus_Sm.
    apply ev_SS. apply IH.
Qed.
(** [] *)

(** **** Exercise: 4 stars, advanced, optional (ev'_ev)

    In general, there may be multiple ways of defining a
    property inductively.  For example, here's a (slightly contrived)
    alternative definition for [ev]: *)

Inductive ev' : nat -> Prop :=
  | ev'_0 : ev' 0
  | ev'_2 : ev' 2
  | ev'_sum n m (Hn : ev' n) (Hm : ev' m) : ev' (n + m).

(** Prove that this definition is logically equivalent to the old one.
    To streamline the proof, use the technique (from the [Logic]
    chapter) of applying theorems to arguments, and note that the same
    technique works with constructors of inductively defined
    propositions. *)

Theorem ev'_ev : forall n, ev' n <-> ev n.
Proof.
  intros n.
  split.
  - intros Hev'. induction Hev' as [| | n' m' Hn IHn Hm IHm].
    + apply ev_0.
    + apply (ev_SS 0 (ev_0)).
    + apply ev_sum. apply IHn. apply IHm.
  - intros Hev. induction Hev as [|n E IH].
    + apply ev'_0.
    + apply (ev'_sum 2 n). apply ev'_2. apply IH.
Qed.
(** [] *)

(** **** Exercise: 3 stars, advanced, especially useful (ev_ev__ev) *)
Theorem ev_ev__ev : forall n m,
  ev (n+m) -> ev n -> ev m.
  (* Hint: There are two pieces of evidence you could attempt to induct upon
      here. If one doesn't work, try the other. *)
Proof.
  intros n m.
  intros Hev_nm.
  intros Hev_n.
  induction Hev_n as [|n' E' IH].
  - simpl in Hev_nm. apply Hev_nm.
  - simpl in Hev_nm. inversion Hev_nm as [|n'm E'' Heq ].
    apply IH in E''. apply E''.
Qed.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (ev_plus_plus)

    This exercise can be completed without induction or case analysis.
    But, you will need a clever assertion and some tedious rewriting.
    Hint: Is [(n+m) + (n+p)] even? *)

Theorem ev_plus_plus : forall n m p,
  ev (n+m) -> ev (n+p) -> ev (m+p).
Proof.
  intros n m p.
  intros Enm Enp.
  assert (H: ev (( n+ m ) + ( n + p ))) . {
    apply ev_sum.
    apply Enm. apply Enp.
  }
  rewrite ( add_comm n p) in H.
  rewrite ( add_shuffle3)  in H.
  rewrite <- (add_assoc) in H.
  rewrite (add_shuffle3 n m n) in H.
  rewrite add_assoc in H.
  assert ( Hxx: forall x, ev (x+x)). {
      induction x as [|x' IHx'].
      - simpl. apply ev_0.
      - simpl. rewrite add_n_plus_Sm. apply ev_SS. apply IHx'.
  }
  apply ev_ev__ev with (n:=(n+n)).
  - rewrite add_comm in H. rewrite ( add_comm p m ) in H. apply H.
  - apply Hxx.
Qed.
(** [] *)

(* ################################################################# *)
(** * Inductive Relations *)

(** A proposition parameterized by a number (such as [ev])
    can be thought of as a _property_ -- i.e., it defines
    a subset of [nat], namely those numbers for which the proposition
    is provable.  In the same way, a two-argument proposition can be
    thought of as a _relation_ -- i.e., it defines a set of pairs for
    which the proposition is provable. *)

Module Playground.

(** Just like properties, relations can be defined inductively.  One
    useful example is the "less than or equal to" relation on numbers
    that we briefly saw above. *)

Inductive le : nat -> nat -> Prop :=
  | le_n (n : nat)                : le n n
  | le_S (n m : nat) (H : le n m) : le n (S m).

Notation "n <= m" := (le n m).

(** (We've written the definition a bit differently this time,
    giving explicit names to the arguments to the constructors and
    moving them to the left of the colons.) *)

(** Proofs of facts about [<=] using the constructors [le_n] and
    [le_S] follow the same patterns as proofs about properties, like
    [ev] above. We can [apply] the constructors to prove [<=]
    goals (e.g., to show that [3<=3] or [3<=6]), and we can use
    tactics like [inversion] to extract information from [<=]
    hypotheses in the context (e.g., to prove that [(2 <= 1) ->
    2+2=5].) *)

(** Here are some sanity checks on the definition.  (Notice that,
    although these are the same kind of simple "unit tests" as we gave
    for the testing functions we wrote in the first few lectures, we
    must construct their proofs explicitly -- [simpl] and
    [reflexivity] don't do the job, because the proofs aren't just a
    matter of simplifying computations.) *)

Theorem test_le1 :
  3 <= 3.
Proof.
  (* WORKED IN CLASS *)
  apply le_n.  Qed.

Theorem test_le2 :
  3 <= 6.
Proof.
  (* WORKED IN CLASS *)
  apply le_S. apply le_S. apply le_S. apply le_n.  Qed.

Theorem test_le3 :
  (2 <= 1) -> 2 + 2 = 5.
Proof.
  (* WORKED IN CLASS *)
  intros H. inversion H. inversion H2.  Qed.

(** The "strictly less than" relation [n < m] can now be defined
    in terms of [le]. *)

Definition lt (n m : nat) := le (S n) m.

Notation "n < m" := (lt n m).

End Playground.

(** **** Exercise: 2 stars, standard, optional (total_relation)

    Define an inductive binary relation [total_relation] that holds
    between every pair of natural numbers. *)

Inductive total_relation : nat -> nat -> Prop :=
  | tot (n m: nat) : total_relation n m.

Theorem total_relation_is_total : forall n m, total_relation n m.
  Proof.
    apply tot.
Qed.
(** [] *)

(** **** Exercise: 2 stars, standard, optional (empty_relation)

    Define an inductive binary relation [empty_relation] (on numbers)
    that never holds. *)

Inductive empty_relation : nat -> nat -> Prop := .

Theorem empty_relation_is_empty : forall n m, ~ empty_relation n m.
  Proof.
    unfold not.
    intros n m.
    intros h.
    destruct h.
Qed.
(** [] *)

(** From the definition of [le], we can sketch the behaviors of
    [destruct], [inversion], and [induction] on a hypothesis [H]
    providing evidence of the form [le e1 e2].  Doing [destruct H]
    will generate two cases. In the first case, [e1 = e2], and it
    will replace instances of [e2] with [e1] in the goal and context.
    In the second case, [e2 = S n'] for some [n'] for which [le e1 n']
    holds, and it will replace instances of [e2] with [S n'].
    Doing [inversion H] will remove impossible cases and add generated
    equalities to the context for further use. Doing [induction H]
    will, in the second case, add the induction hypothesis that the
    goal holds when [e2] is replaced with [n']. *)

(** Here are a number of facts about the [<=] and [<] relations that
    we are going to need later in the course.  The proofs make good
    practice exercises. *)

(** **** Exercise: 5 stars, standard, optional (le_and_lt_facts) *)

Lemma lt_implies_le: forall a b, lt a b -> le a b.
Proof.
  intros a b.
  unfold lt.
  generalize dependent a.
  induction b.
  - intros a h. inversion h.
  - intros a h. inversion h.
    + apply le_S. apply le_n.
    + apply le_S. apply IHb. assumption.
Qed.

  
Lemma le_trans : forall m n o, m <= n -> n <= o -> m <= o.
Proof.
  intros n m o.
  intros le_nm le_mo.
  induction m as [|m' IHm] .
  + assert (Hn: n = 0). { inversion le_nm. reflexivity. }
    rewrite Hn.
    destruct o as [|o' ] eqn:E.
    apply le_n. apply le_mo.
  + inversion le_nm as [|n' E H].
    - apply le_mo.
    - apply lt_implies_le in le_mo. apply IHm. assumption. assumption.
Qed.

Theorem O_le_n : forall n,
  0 <= n.
Proof.
  induction n.
  apply le_n.
  apply le_S. apply IHn.
Qed.

Theorem n_le_m__Sn_le_Sm : forall n m,
  n <= m -> S n <= S m.
Proof.
  intros n m.
  induction m.
  - intros h. inversion h. apply le_n.
  - intros h. inversion h as [|n' E Heq].
    + apply le_n.
    + apply IHm in E. apply le_S. apply E.
Qed.

Theorem Sn_le_Sm__n_le_m : forall n m,
  S n <= S m -> n <= m.
Proof.
  intros n m.
  generalize dependent n.
  induction m.
  + intros n h. inversion h as [E|n' E Heq]. apply le_n. inversion E.
  + intros n h. inversion h as [E|n' E Heq].
    - apply le_n.
    - apply le_S. apply IHm. apply E.
Qed.

(* TODO: Continue from here*)
Theorem lt_ge_cases : forall n m,
  n < m \/ n >= m.
Proof.
  intros n m.
  generalize dependent n.
  induction m as [|m' IHm].
  + right. apply O_le_n.
  + intros n. specialize IHm with (pred n).
    destruct n as [|n'] eqn:E.
    * left. unfold lt. apply n_le_m__Sn_le_Sm. apply O_le_n.
    * simpl in IHm. destruct IHm as [H|H].
      - left. unfold lt in H. unfold lt. apply n_le_m__Sn_le_Sm. apply H.
      - right. unfold ge in H. unfold ge. apply n_le_m__Sn_le_Sm in H. apply H.
Qed.


Theorem le_plus_l : forall a b,
  a <= a + b.
Proof.
  intros a b.
  induction b as [|b' Ihb].
  + rewrite add_0_r. apply le_n.
  + Search (?x + S ?y). rewrite PeanoNat.Nat.add_succ_r. apply le_S. apply Ihb.
Qed.

Theorem plus_le : forall n1 n2 m,
  n1 + n2 <= m ->
  n1 <= m /\ n2 <= m.
Proof.
  intros n1 n2 m.
  intros h.
  induction m as [|m' IHm].
  + inversion h.
    - split. apply le_plus_l. rewrite add_comm. apply le_plus_l.
  + inversion h as [H| m'' E Heq].
    - split. apply le_plus_l. rewrite add_comm. apply le_plus_l.
    - apply IHm in E. split.
      * apply le_S. apply E.
      * apply le_S. apply E.
Qed.

Theorem add_le_cases : forall n m p q,
  n + m <= p + q -> n <= p \/ m <= q.
  (** Hint: May be easiest to prove by induction on [n]. *)
Proof.
  (* intros n m p q. *)
  induction n as [|n' IHn].
  + simpl. intros m p q h. left. apply O_le_n.
  + intros m p q h. rewrite plus_Sn_m in h.
    destruct p as [|p'] eqn:E.
    - simpl in h.
      specialize IHn with (m:= S m) (p:=0) (q:=q). simpl in IHn.
      rewrite <- plus_n_Sm in IHn.
      apply IHn in h as h'.
      rewrite <- plus_Sn_m in h.
      apply plus_le in h. destruct h as [_ H]. right. apply H.
    - specialize IHn with (m:= S m) (p:=p') (q:= S q).
      rewrite plus_Sn_m in h.
      rewrite <- plus_n_Sm in IHn.
      rewrite <- ( plus_n_Sm p' q) in IHn.
      apply IHn in h.
      destruct h as [H|H].
      * left. apply n_le_m__Sn_le_Sm. apply H.
      * right. apply Sn_le_Sm__n_le_m in H. apply H.
Qed.

Theorem plus_le_compat_l : forall n m p,
  n <= m ->
  p + n <= p + m.
Proof.
  intros n m p.
  induction p as [|p' IHp].
  + simpl. intros h. apply h.
  + simpl. intros h. apply IHp in h.
    apply n_le_m__Sn_le_Sm. apply h.
Qed.

Theorem plus_le_compat_r : forall n m p,
  n <= m ->
  n + p <= m + p.
Proof.
  intros n m p.
  induction p as [|p' IHp].
  + intros h. rewrite add_0_r. rewrite ( add_0_r m ). apply h.
  + intros h. apply IHp in h. rewrite add_n_plus_Sm .
    rewrite ( add_n_plus_Sm m p' ).
    apply n_le_m__Sn_le_Sm.
    apply h.
Qed.

Theorem le_plus_trans : forall n m p,
  n <= m ->
  n <= m + p.
Proof.
  intros n m p.
  induction p as [|p' IHp].
  + intros h. rewrite add_0_r. apply h.
  + intros h. rewrite add_n_plus_Sm.
    apply le_S.
    apply IHp in h.
    apply h.
Qed.

Theorem n_lt_m__n_le_m : forall n m,
  n < m ->
  n <= m.
Proof.
  intros n.
  unfold lt.
  destruct n as [|n'].
  + intros m h. apply O_le_n.
  + intros m h. apply le_S in h. apply Sn_le_Sm__n_le_m in h.
    apply h.
Qed.

Theorem plus_lt : forall n1 n2 m,
  n1 + n2 < m ->
  n1 < m /\ n2 < m.
Proof.
  unfold lt.
  intros n1 n2 m.
  generalize dependent n1.
  generalize dependent n2.
  induction m as [|m' Ihm].
  + intros n1 n2. intros h. inversion h.
  + intros n2 n1 h.
    inversion h as [|m'' E Heq].
    - split.
      * apply n_le_m__Sn_le_Sm. apply le_plus_l.
      * apply n_le_m__Sn_le_Sm. rewrite add_comm. apply le_plus_l.
    - apply Ihm in E. split.
      * apply le_S. apply E.
      * apply le_S. apply E.
Qed.

(** **** Exercise: 4 stars, standard, optional (more_le_exercises) *)
Theorem leb_complete : forall n m,
  n <=? m = true -> n <= m.
Proof.
  induction n as [|n' IHn].
  + intros m. intros h. apply O_le_n.
  + intros m h.
    simpl in h.
    destruct m as [|m'] eqn:E.
    * discriminate h.
    * apply IHn in h. apply n_le_m__Sn_le_Sm. apply h.
Qed.

Lemma leb_n_m_implies_leb_n_Sm: forall n m, n <=? m = true -> n <=? S m = true .
Proof.
  induction n as [|n' IHn].
  + simpl. reflexivity.
  + intros m h. simpl in h.
    simpl.
    destruct m as [|m'] eqn:E.
    - discriminate h.
    - apply IHn in h. apply h.
Qed.

Theorem leb_correct : forall n m,
  n <= m ->
  n <=? m = true.
  (** Hint: May be easiest to prove by induction on [m]. *)
Proof.
  intros n m h.
  generalize dependent n.
  induction m as [|m' IHm].
  + intros n h. destruct n eqn:E. reflexivity.
    Search (S ?x <= 0). apply PeanoNat.Nat.nle_succ_0 in h. destruct h.
  + intros n h. inversion h as [|m'' E Heq].
    * rewrite leb_refl. reflexivity.
    * apply IHm in E. apply leb_n_m_implies_leb_n_Sm in E. apply E.
Qed.

(** Hint: The next two can easily be proved without using [induction]. *)

Theorem leb_iff : forall n m,
  n <=? m = true <-> n <= m.
Proof.
  intros n m.
  split.
  - apply leb_complete.
  - apply leb_correct.
Qed.

Theorem leb_true_trans : forall n m o,
  n <=? m = true -> m <=? o = true -> n <=? o = true.
Proof.
  intros n m o.
  intros hnm hmo.
  apply leb_complete in hnm.
  apply leb_complete in hmo.
  apply leb_correct.
  apply le_trans with (m).
  apply hnm.
  apply hmo.
Qed.

Module R.

(** **** Exercise: 3 stars, standard, especially useful (R_provability)

    We can define three-place relations, four-place relations,
    etc., in just the same way as binary relations.  For example,
    consider the following three-place relation on numbers: *)

Inductive R : nat -> nat -> nat -> Prop :=
  | c1                                     : R 0     0     0
  | c2 m n o (H : R m     n     o        ) : R (S m) n     (S o)
  | c3 m n o (H : R m     n     o        ) : R m     (S n) (S o)
  | c4 m n o (H : R (S m) (S n) (S (S o))) : R m     n     o
  | c5 m n o (H : R m     n     o        ) : R n     m     o
.

(** - Which of the following propositions are provable?
      - [R 1 1 2] (Ans: Yes)
      - [R 2 2 6] (Ans: No)

    - If we dropped constructor [c5] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer. (Ans: this is commutative constructor, we could probably prove that from the first 3 constructors actually, so wouldn't change much)

    - If we dropped constructor [c4] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer. (Ans: Wouldn't change anything) *)

(* FILL IN HERE *)

(* Do not modify the following line: *)
Definition manual_grade_for_R_provability : option (nat*string) := None.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (R_fact)

    The relation [R] above actually encodes a familiar function.
    Figure out which function; then state and prove this equivalence
    in Coq. *)

Definition fR : nat -> nat -> nat := Nat.add.

  (* (* REPLACE THIS LINE WITH ":= _your_definition_ ." *). Admitted. *)

Theorem R_equiv_fR : forall m n o, R m n o <-> fR m n = o.
Proof.
  intros m n o.
  split.
  - intros h.
    induction h.
    + reflexivity.
    + unfold fR. unfold fR in IHh.
      rewrite plus_Sn_m. f_equal. apply IHh.
    + unfold fR. unfold fR in IHh.
      rewrite <- plus_n_Sm. f_equal. apply IHh.
    + unfold fR in IHh. simpl in IHh.
      rewrite <- plus_n_Sm in IHh.
      injection IHh as h'. apply h'.
    + unfold fR. unfold fR in IHh.
      rewrite add_comm. apply IHh.
  - intros h. unfold fR in h.
    generalize dependent m.
    generalize dependent n.
    induction o as [|o' IHo].
    + intros m n h. Search ( ?x + ?y = 0  ). apply PeanoNat.Nat.eq_add_0 in h.
      destruct h as [Hm Hn]. rewrite Hm, Hn. apply c1.
    + induction n as [|n' IHn].
      * intros m h. destruct m as [|m'].
        ** simpl in h. rewrite <- h. apply c1.
        ** simpl in h. injection h as h'. apply IHo in h'. apply c2. apply h'.
      * induction m as [|m' IHm].
        ** intros h. rewrite <- plus_n_Sm in h.
          injection h as h'. rewrite <- ( plus_O_n n') in h'.
          apply IHo in h'.
          apply c3. apply h'.
        ** intros h. apply c2.
           specialize IHo with (m:=m') (n:=S n').
           simpl in h.
           injection h as h'.
           apply IHo in h'.
           apply h'.
Qed.
(** [] *)

End R.

(** **** Exercise: 3 stars, advanced (subsequence)

    A list is a _subsequence_ of another list if all of the elements
    in the first list occur in the same order in the second list,
    possibly with some extra elements in between. For example,

      [1;2;3]

    is a subsequence of each of the lists

      [1;2;3]
      [1;1;1;2;2;3]
      [1;2;7;3]
      [5;6;1;9;9;2;7;3;8]

    but it is _not_ a subsequence of any of the lists

      [1;2]
      [1;3]
      [5;6;2;1;7;3;8].

    - Define an inductive proposition [subseq] on [list nat] that
      captures what it means to be a subsequence. (Hint: You'll need
      three cases.)

    - Prove [subseq_refl] that subsequence is reflexive, that is,
      any list is a subsequence of itself.

    - Prove [subseq_app] that for any lists [l1], [l2], and [l3],
      if [l1] is a subsequence of [l2], then [l1] is also a subsequence
      of [l2 ++ l3].

    - (Harder) Prove [subseq_trans] that subsequence is
      transitive -- that is, if [l1] is a subsequence of [l2] and [l2]
      is a subsequence of [l3], then [l1] is a subsequence of [l3]. *)

Inductive subseq : list nat -> list nat -> Prop :=
  | ss_empty ( l: list nat ) : subseq ([]) l
  | ss_any_hd (h:nat) (l1 l2:list nat) : (subseq l1 l2) -> subseq l1 (h::l2)
  | ss_same_hd (h:nat) (l1 l2:list nat) : (subseq l1 l2) -> subseq (h::l1) (h::l2)
.


Lemma cons_is_hd_app_tl : forall ( X: Type ) ( hd: X ) (tl: list X ) , hd::tl = [hd] ++ tl .
Proof.
  intros X hd tl.
  simpl app.
  reflexivity.
Qed.

Theorem subseq_refl : forall (l : list nat), subseq l l.
Proof.
  induction l as [|hd tl IHl].
  + apply ss_empty.
  + apply ss_same_hd. apply IHl.
Qed.

Theorem subseq_app : forall (l1 l2 l3 : list nat),
  subseq l1 l2 ->
  subseq l1 (l2 ++ l3).
Proof.
  intros l1 l2 l3 H.
  induction H.
  - apply ss_empty.
  - rewrite cons_is_hd_app_tl . rewrite <-app_assoc.
    rewrite <- cons_is_hd_app_tl.
    apply ss_any_hd. assumption.
  - rewrite ( cons_is_hd_app_tl _ h l2 ). rewrite <-app_assoc.
    rewrite <- cons_is_hd_app_tl.
    apply ss_same_hd. assumption.
Qed.

Lemma app_result_empty_imp_all_empty: forall (X:Type) ( l1 l2: list X ) , l1 ++ l2 = [] -> l1 = [] /\ l2 = [].
Proof.
  intros X.
  induction l1 as [|hd tl IHl1].
  + intros l2. simpl. intros h. split. reflexivity. apply h.
  + intros l2. simpl. intros h.
    unfold app in h. discriminate h.
Qed.

Lemma not_subseq_of_empty: forall hd tl, not (subseq (hd::tl) []).
Proof.
  intros hd tl.
  unfold not.
  intros h.
  inversion h.
Qed.

Theorem subseq_trans : forall (l1 l2 l3 : list nat),
  subseq l1 l2 ->
  subseq l2 l3 ->
  subseq l1 l3.
Proof.
  (* Hint: be careful about what you are doing induction on and which
     other things need to be generalized... *)
  intros l1 l2 l3 H12 H23.
  generalize dependent l1.
  induction H23.
  - intros l1 h. inversion h. apply ss_empty.
  - intros . apply ss_any_hd. apply IHsubseq. assumption.
  - intros . inversion H12.
    * apply ss_empty.
    * apply ss_any_hd. apply IHsubseq in H1. assumption.
    * apply ss_same_hd. apply IHsubseq in H1. assumption.
Qed.
(** [] *)

(** **** Exercise: 2 stars, standard, optional (R_provability2)

    Suppose we give Coq the following definition:

    Inductive R : nat -> list nat -> Prop :=
      | c1                    : R 0     []
      | c2 n l (H: R n     l) : R (S n) (n :: l)
      | c3 n l (H: R (S n) l) : R n     l.

    Which of the following propositions are provable?

    - [R 2 [1;0]]
    - [R 1 [1;2;1;0]]
    - [R 6 [3;2;1;0]]  *)

(* FILL IN HERE

    [] *)

(* ################################################################# *)
(** * A Digression on Notation *)

(** There are several equivalent ways of writing inductive
    types.  We've mostly seen this style... *)

Module bin1.
Inductive bin : Type :=
  | Z
  | B0 (n : bin)
  | B1 (n : bin).
End bin1.

(** ... which omits the result types because they are all the same (i.e., [bin]). *)

(** It is completely equivalent to this... *)
Module bin2.
Inductive bin : Type :=
  | Z            : bin
  | B0 (n : bin) : bin
  | B1 (n : bin) : bin.
End bin2.

(** ... where we fill them in, and this... *)

Module bin3.
Inductive bin : Type :=
  | Z : bin
  | B0 : bin -> bin
  | B1 : bin -> bin.
End bin3.

(** ... where we put everything on the right of the colon. *)

(** For inductively defined _propositions_, we need to explicitly give
    the result type for each constructor (because they are not all the
    same), so the first style doesn't make sense, but we can use
    either the second or the third interchangeably. *)

(* ################################################################# *)
(** * Case Study: Regular Expressions *)

(** The [ev] property provides a simple example for
    illustrating inductive definitions and the basic techniques for
    reasoning about them, but it is not terribly exciting -- after
    all, it is equivalent to the two non-inductive definitions of
    evenness that we had already seen, and does not seem to offer any
    concrete benefit over them.

    To give a better sense of the power of inductive definitions, we
    now show how to use them to model a classic concept in computer
    science: _regular expressions_. *)

(** Regular expressions are a simple language for describing sets of
    strings.  Their syntax is defined as follows: *)

Inductive reg_exp (T : Type) : Type :=
  | EmptySet
  | EmptyStr
  | Char (t : T)
  | App (r1 r2 : reg_exp T)
  | Union (r1 r2 : reg_exp T)
  | Star (r : reg_exp T).

Arguments EmptySet {T}.
Arguments EmptyStr {T}.
Arguments Char {T} _.
Arguments App {T} _ _.
Arguments Union {T} _ _.
Arguments Star {T} _.

(** Note that this definition is _polymorphic_: Regular
    expressions in [reg_exp T] describe strings with characters drawn
    from [T] -- that is, lists of elements of [T].

    (Technical aside: We depart slightly from standard practice in
    that we do not require the type [T] to be finite.  This results in
    a somewhat different theory of regular expressions, but the
    difference is not significant for present purposes.) *)

(** We connect regular expressions and strings via the following
    rules, which define when a regular expression _matches_ some
    string:

      - The expression [EmptySet] does not match any string.

      - The expression [EmptyStr] matches the empty string [[]].

      - The expression [Char x] matches the one-character string [[x]].

      - If [re1] matches [s1], and [re2] matches [s2],
        then [App re1 re2] matches [s1 ++ s2].

      - If at least one of [re1] and [re2] matches [s],
        then [Union re1 re2] matches [s].

      - Finally, if we can write some string [s] as the concatenation
        of a sequence of strings [s = s_1 ++ ... ++ s_k], and the
        expression [re] matches each one of the strings [s_i],
        then [Star re] matches [s].

        In particular, the sequence of strings may be empty, so
        [Star re] always matches the empty string [[]] no matter what
        [re] is. *)

(** We can easily translate this informal definition into an
    [Inductive] one as follows.  We use the notation [s =~ re] in
    place of [exp_match s re]. *)

Reserved Notation "s =~ re" (at level 80).

Inductive exp_match {T} : list T -> reg_exp T -> Prop :=
  | MEmpty : [] =~ EmptyStr
  | MChar x : [x] =~ (Char x)
  | MApp s1 re1 s2 re2
             (H1 : s1 =~ re1)
             (H2 : s2 =~ re2)
           : (s1 ++ s2) =~ (App re1 re2)
  | MUnionL s1 re1 re2
                (H1 : s1 =~ re1)
              : s1 =~ (Union re1 re2)
  | MUnionR re1 s2 re2
                (H2 : s2 =~ re2)
              : s2 =~ (Union re1 re2)
  | MStar0 re : [] =~ (Star re)
  | MStarApp s1 s2 re
                 (H1 : s1 =~ re)
                 (H2 : s2 =~ (Star re))
               : (s1 ++ s2) =~ (Star re)

  where "s =~ re" := (exp_match s re).

(** Notice that these rules are not _quite_ the same as the
    informal ones that we gave at the beginning of the section.
    First, we don't need to include a rule explicitly stating that no
    string matches [EmptySet]; we just don't happen to include any
    rule that would have the effect of some string matching
    [EmptySet].  (Indeed, the syntax of inductive definitions doesn't
    even _allow_ us to give such a "negative rule.")

    Second, the informal rules for [Union] and [Star] correspond
    to two constructors each: [MUnionL] / [MUnionR], and [MStar0] /
    [MStarApp].  The result is logically equivalent to the original
    rules but more convenient to use in Coq, since the recursive
    occurrences of [exp_match] are given as direct arguments to the
    constructors, making it easier to perform induction on evidence.
    (The [exp_match_ex1] and [exp_match_ex2] exercises below ask you
    to prove that the constructors given in the inductive declaration
    and the ones that would arise from a more literal transcription of
    the informal rules are indeed equivalent.)

    Let's illustrate these rules with a few examples. *)

Example reg_exp_ex1 : [1] =~ Char 1.
Proof.
  apply MChar.
Qed.

Example reg_exp_ex2 : [1; 2] =~ App (Char 1) (Char 2).
Proof.
  apply (MApp [1]).
  - apply MChar.
  - apply MChar.
Qed.

(** (Notice how the last example applies [MApp] to the string
    [[1]] directly.  Since the goal mentions [[1; 2]] instead of
    [[1] ++ [2]], Coq wouldn't be able to figure out how to split
    the string on its own.)

    Using [inversion], we can also show that certain strings do _not_
    match a regular expression: *)

Example reg_exp_ex3 : ~ ([1; 2] =~ Char 1).
Proof.
  intros H. inversion H.
Qed.

(** We can define helper functions for writing down regular
    expressions. The [reg_exp_of_list] function constructs a regular
    expression that matches exactly the list that it receives as an
    argument: *)

Fixpoint reg_exp_of_list {T} (l : list T) :=
  match l with
  | [] => EmptyStr
  | x :: l' => App (Char x) (reg_exp_of_list l')
  end.

Example reg_exp_ex4 : [1; 2; 3] =~ reg_exp_of_list [1; 2; 3].
Proof.
  simpl. apply (MApp [1]).
  { apply MChar. }
  apply (MApp [2]).
  { apply MChar. }
  apply (MApp [3]).
  { apply MChar. }
  apply MEmpty.
Qed.

(** We can also prove general facts about [exp_match].  For instance,
    the following lemma shows that every string [s] that matches [re]
    also matches [Star re]. *)

Lemma MStar1 :
  forall T s (re : reg_exp T) ,
    s =~ re ->
    s =~ Star re.
Proof.
  intros T s re H.
  rewrite <- (app_nil_r _ s).
  apply MStarApp.
  - apply H.
  - apply MStar0.
Qed.

(** (Note the use of [app_nil_r] to change the goal of the theorem to
    exactly the shape expected by [MStarApp].) *)

(** **** Exercise: 3 stars, standard (exp_match_ex1)

    The following lemmas show that the informal matching rules given
    at the beginning of the chapter can be obtained from the formal
    inductive definition. *)

Lemma empty_is_empty : forall T (s : list T),
  ~ (s =~ EmptySet).
Proof.
  intros T s.
  intros h.
  inversion h.
Qed.

Lemma MUnion' : forall T (s : list T) (re1 re2 : reg_exp T),
  s =~ re1 \/ s =~ re2 ->
  s =~ Union re1 re2.
Proof.
  intros T s re1 re2 [Hre1|Hre2].
  - apply MUnionL. assumption.
  - apply MUnionR . assumption.
Qed.

(** The next lemma is stated in terms of the [fold] function from the
    [Poly] chapter: If [ss : list (list T)] represents a sequence of
    strings [s1, ..., sn], then [fold app ss []] is the result of
    concatenating them all together. *)

Lemma MStar' : forall T (ss : list (list T)) (re : reg_exp T),
  (forall s, In s ss -> s =~ re) ->
  fold app ss [] =~ Star re.
Proof.
  intros T ss re h.
  induction ss as [|hd tl IHss].
  + simpl.  apply MStar0.
  + simpl.
    apply MStarApp.
    - specialize h with (s:=hd). apply h. simpl. left. reflexivity.
    - apply IHss. intros s.
      specialize h with (s:=s).
      simpl in h.
      intros Hstl.
      apply h.
      right.
      assumption.
Qed.
(** [] *)

(** Since the definition of [exp_match] has a recursive
    structure, we might expect that proofs involving regular
    expressions will often require induction on evidence. *)

(** For example, suppose we want to prove the following intuitive
    result: If a regular expression [re] matches some string [s], then
    all elements of [s] must occur as character literals somewhere in
    [re].

    To state this as a theorem, we first define a function [re_chars]
    that lists all characters that occur in a regular expression: *)

Fixpoint re_chars {T} (re : reg_exp T) : list T :=
  match re with
  | EmptySet => []
  | EmptyStr => []
  | Char x => [x]
  | App re1 re2 => re_chars re1 ++ re_chars re2
  | Union re1 re2 => re_chars re1 ++ re_chars re2
  | Star re => re_chars re
  end.

(** The main theorem: *)

Theorem in_re_match : forall T (s : list T) (re : reg_exp T) (x : T),
  s =~ re ->
  In x s ->
  In x (re_chars re).
Proof.
  intros T s re x Hmatch Hin.
  induction Hmatch
    as [| x'
        | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
        | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
        | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2].
  (* WORKED IN CLASS *)
  - (* MEmpty *)
    simpl in Hin. destruct Hin.
  - (* MChar *)
    simpl. simpl in Hin.
    apply Hin.
  - (* MApp *)
    simpl.

(** Something interesting happens in the [MApp] case.  We obtain
    _two_ induction hypotheses: One that applies when [x] occurs in
    [s1] (which matches [re1]), and a second one that applies when [x]
    occurs in [s2] (which matches [re2]). *)

    rewrite In_app_iff in *.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      left. apply (IH1 Hin).
    + (* In x s2 *)
      right. apply (IH2 Hin).
  - (* MUnionL *)
    simpl. rewrite In_app_iff.
    left. apply (IH Hin).
  - (* MUnionR *)
    simpl. rewrite In_app_iff.
    right. apply (IH Hin).
  - (* MStar0 *)
    destruct Hin.
  - (* MStarApp *)
    simpl.

(** Here again we get two induction hypotheses, and they illustrate
    why we need induction on evidence for [exp_match], rather than
    induction on the regular expression [re]: The latter would only
    provide an induction hypothesis for strings that match [re], which
    would not allow us to reason about the case [In x s2]. *)

    rewrite In_app_iff in Hin.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      apply (IH1 Hin).
    + (* In x s2 *)
      apply (IH2 Hin).
Qed.

(** **** Exercise: 4 stars, standard (re_not_empty)

    Write a recursive function [re_not_empty] that tests whether a
    regular expression matches some string. Prove that your function
    is correct. *)

Fixpoint re_not_empty {T : Type} (re : reg_exp T) : bool :=
  match re with
  | EmptySet => false
  | EmptyStr => true
  | Char t => true
  | App r1 r2 =>  re_not_empty r1 && re_not_empty r2
  | Union r1 r2 => re_not_empty r1 || re_not_empty r2
  | Star r => true || re_not_empty r (* matches empty *)
  end.

Lemma re_not_empty_correct : forall T (re : reg_exp T),
  (exists s, s =~ re) <-> re_not_empty re = true.
Proof.
  intros t re.
  split.
  - intros [s Hs].
    induction Hs.
    * reflexivity.
    * reflexivity.
    * simpl. apply andb_true_iff.
      split. assumption. assumption.
    * simpl. apply orb_true_iff. left. assumption.
    * simpl. apply orb_true_iff. right. assumption.
    * reflexivity.
    * assumption.
  - intros h.
    induction re.
    * inversion h.
    * exists []. apply MEmpty.
    * exists [t0]. apply MChar.
    * simpl in h. apply andb_true_iff in h as [hl hr].
      apply IHre1 in hl as [s1 hs1].
      apply IHre2 in hr as [s2 hs2].
      exists (s1++s2). apply MApp. assumption. assumption.
    * simpl in *. apply orb_true_iff in h as [hl|hr].
      + apply IHre1 in hl as [s hs]. exists s. apply MUnionL. assumption.
      + apply IHre2 in hr as [s hs]. exists s. apply MUnionR. assumption.
    * exists []. apply MStar0.
Qed.
(** [] *)

(* ================================================================= *)
(** ** The [remember] Tactic *)

(** One potentially confusing feature of the [induction] tactic is
    that it will let you try to perform an induction over a term that
    isn't sufficiently general.  The effect of this is to lose
    information (much as [destruct] without an [eqn:] clause can do),
    and leave you unable to complete the proof.  Here's an example: *)

Lemma star_app: forall T (s1 s2 : list T) (re : reg_exp T),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.

(** Now, just doing an [inversion] on [H1] won't get us very far in
    the recursive cases. (Try it!). So we need induction (on
    evidence!). Here is a naive first attempt. *)

  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** But now, although we get seven cases (as we would expect
    from the definition of [exp_match]), we have lost a very important
    bit of information from [H1]: the fact that [s1] matched something
    of the form [Star re].  This means that we have to give proofs for
    _all_ seven constructors of this definition, even though all but
    two of them ([MStar0] and [MStarApp]) are contradictory.  We can
    still get the proof to go through for a few constructors, such as
    [MEmpty]... *)

  - (* MEmpty *)
    simpl. intros H. apply H.

(** ... but most cases get stuck.  For [MChar], for instance, we
    must show

      s2     =~ Char x' ->
      x'::s2 =~ Char x'

    which is clearly impossible. *)

  - (* MChar. *) intros H. simpl. (* Stuck... *)
Abort.

(** The problem here is that [induction] over a Prop hypothesis
    only works properly with hypotheses that are "completely
    general," i.e., ones in which all the arguments are variables,
    as opposed to more complex expressions like [Star re].

    (In this respect, [induction] on evidence behaves more like
    [destruct]-without-[eqn:] than like [inversion].)

    A possible, but awkward, way to solve this problem is "manually
    generalizing" over the problematic expressions by adding
    explicit equality hypotheses to the lemma: *)

Lemma star_app: forall T (s1 s2 : list T) (re re' : reg_exp T),
  re' = Star re ->
  s1 =~ re' ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.

(** We can now proceed by performing induction over evidence
    directly, because the argument to the first hypothesis is
    sufficiently general, which means that we can discharge most cases
    by inverting the [re' = Star re] equality in the context.

    This works, but it makes the statement of the lemma a bit ugly.
    Fortunately, there is a better way... *)
Abort.

(** The tactic [remember e as x] causes Coq to (1) replace all
    occurrences of the expression [e] by the variable [x], and (2) add
    an equation [x = e] to the context.  Here's how we can use it to
    show the above result: *)

Lemma star_app: forall T (s1 s2 : list T) (re : reg_exp T),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.
  remember (Star re) as re'.

(** We now have [Heqre' : re' = Star re]. *)

  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** The [Heqre'] is contradictory in most cases, allowing us to
    conclude immediately. *)

  - (* MEmpty *)  discriminate.
  - (* MChar *)   discriminate.
  - (* MApp *)    discriminate.
  - (* MUnionL *) discriminate.
  - (* MUnionR *) discriminate.

(** The interesting cases are those that correspond to [Star].  Note
    that the induction hypothesis [IH2] on the [MStarApp] case
    mentions an additional premise [Star re'' = Star re], which
    results from the equality generated by [remember]. *)

  - (* MStar0 *)
    intros H. apply H.

  - (* MStarApp *)
    intros H1. rewrite <- app_assoc.
    apply MStarApp.
    + apply Hmatch1.
    + apply IH2.
      * apply Heqre'.
      * apply H1.
Qed.

(** **** Exercise: 4 stars, standard, optional (exp_match_ex2) *)

(** The [MStar''] lemma below (combined with its converse, the
    [MStar'] exercise above), shows that our definition of [exp_match]
    for [Star] is equivalent to the informal one given previously. *)

(* Lemma MStar'' : forall T (s : list T) (re : reg_exp T), *)
(*   s =~ Star re -> *)
(*   exists ss : list (list T), *)
(*     s = fold app ss [] *)
(*     /\ forall s', In s' ss -> s' =~ re. *)
(* Proof. *)
(*   intros. *)
(*   remember (Star re) as re'. *)
(*   induction H. *)
(*   - inversion Heqre'. *)
(*   - inversion Heqre'. *)
(*   - inversion Heqre'. *)
(*   - inversion Heqre'. *)
(*   - inversion Heqre'. *)
(*   - inversion Heqre'. *)
(*     exists []. *)
(*     split. *)
(*     + reflexivity. *)
(*     + intros. inversion H. *)
(*   - inversion Heqre'. *)
(*     rewrite -> H2 in *. *)
(*     induction s1. *)
(*     + intros. simpl. apply IHexp_match2. apply Heqre'. *)
(*     + intros. *)
(*       apply IHexp_match2 in Heqre'. *)
(*       destruct Heqre'. *)
(*       destruct H1. *)
(*       exists ((x::s1)::x0). *)
(*       split. *)
(*       * rewrite -> H1. simpl. reflexivity. *)
(*       * intros. simpl. *)
(*         destruct H4. *)
(*         { rewrite -> H4. apply H. } *)
(*         { apply H3 in H4. apply H4. } *)
(* Qed. *)



Lemma MStar'' : forall T (s : list T) (re : reg_exp T),
  s =~ Star re ->
  exists ss : list (list T),
    s = fold app ss []
    /\ forall s', In s' ss -> s' =~ re.
Proof.
  intros  T s re H.
  remember (Star re) as re'.
  induction H.
  * discriminate.
  * discriminate.
  * discriminate.
  * discriminate.
  * discriminate.
  * exists []. simpl. split. reflexivity.
    intros s' contra. destruct contra.
  * injection Heqre'.
    intros Heq.
    induction s1.
    - simpl. apply IHexp_match2. assumption.
    - simpl.
      apply IHexp_match2 in Heqre' as [ss [Hss1 Hss2]].
      exists (( x::s1 ):: ss).
      split.
      + simpl. rewrite Hss1. reflexivity.
      + intros.
        simpl in H1.
        destruct H1 as [H11 | H12].
        ++ rewrite <- H11. rewrite <- Heq. assumption.
        ++ apply Hss2. assumption.
Qed.
(** [] *)

(** **** Exercise: 5 stars, advanced (weak_pumping)

    One of the first really interesting theorems in the theory of
    regular expressions is the so-called _pumping lemma_, which
    states, informally, that any sufficiently long string [s] matching
    a regular expression [re] can be "pumped" by repeating some middle
    section of [s] an arbitrary number of times to produce a new
    string also matching [re].  (For the sake of simplicity in this
    exercise, we consider a slightly weaker theorem than is usually
    stated in courses on automata theory -- hence the name
    [weak_pumping].)

    To get started, we need to define "sufficiently long."  Since we
    are working in a constructive logic, we actually need to be able
    to calculate, for each regular expression [re], the minimum length
    for strings [s] to guarantee "pumpability." *)

Module Pumping.

Fixpoint pumping_constant {T} (re : reg_exp T) : nat :=
  match re with
  | EmptySet => 1
  | EmptyStr => 1
  | Char _ => 2
  | App re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Union re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Star r => pumping_constant r
  end.

(** You may find these lemmas about the pumping constant useful when
    proving the pumping lemma below. *)

Lemma pumping_constant_ge_1 :
  forall T (re : reg_exp T),
    pumping_constant re >= 1.
Proof.
  intros T re. induction re.
  - (* EmptySet *)
    apply le_n.
  - (* EmptyStr *)
    apply le_n.
  - (* Char *)
    apply le_S. apply le_n.
  - (* App *)
    simpl.
    apply le_trans with (n:=pumping_constant re1).
    apply IHre1. apply le_plus_l.
  - (* Union *)
    simpl.
    apply le_trans with (n:=pumping_constant re1).
    apply IHre1. apply le_plus_l.
  - (* Star *)
    simpl. apply IHre.
Qed.

Lemma pumping_constant_0_false :
  forall T (re : reg_exp T),
    pumping_constant re = 0 -> False.
Proof.
  intros T re H.
  assert (Hp1 : pumping_constant re >= 1).
  { apply pumping_constant_ge_1. }
  rewrite H in Hp1. inversion Hp1.
Qed.

(** Next, it is useful to define an auxiliary function that repeats a
    string (appends it to itself) some number of times. *)

Fixpoint napp {T} (n : nat) (l : list T) : list T :=
  match n with
  | 0 => []
  | S n' => l ++ napp n' l
  end.

(** This auxiliary lemma might also be useful in your proof of the
    pumping lemma. *)

Lemma napp_plus: forall T (n m : nat) (l : list T),
  napp (n + m) l = napp n l ++ napp m l.
Proof.
  intros T n m l.
  induction n as [|n IHn].
  - reflexivity.
  - simpl. rewrite IHn, app_assoc. reflexivity.
Qed.

Lemma napp_star :
  forall T m s1 s2 (re : reg_exp T),
    s1 =~ re -> s2 =~ Star re ->
    napp m s1 ++ s2 =~ Star re.
Proof.
  intros T m s1 s2 re Hs1 Hs2.
  induction m.
  - simpl. apply Hs2.
  - simpl. rewrite <- app_assoc.
    apply MStarApp.
    + apply Hs1.
    + apply IHm.
Qed.

(** The (weak) pumping lemma itself says that, if [s =~ re] and if the
    length of [s] is at least the pumping constant of [re], then [s]
    can be split into three substrings [s1 ++ s2 ++ s3] in such a way
    that [s2] can be repeated any number of times and the result, when
    combined with [s1] and [s3], will still match [re].  Since [s2] is
    also guaranteed not to be the empty string, this gives us
    a (constructive!) way to generate strings matching [re] that are
    as long as we like. *)

Lemma weak_pumping : forall T (re : reg_exp T) s,
  s =~ re ->
  pumping_constant re <= length s ->
  exists s1 s2 s3,
    s = s1 ++ s2 ++ s3 /\
    s2 <> [] /\
    forall m, s1 ++ napp m s2 ++ s3 =~ re.

(** Complete the proof below. Several of the lemmas about [le] that
    were in an optional exercise earlier in this chapter may also be
    useful. *)
Proof.
  intros T re s Hmatch.
  induction Hmatch
    as [ | x | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
       | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
       | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2 ].
  - (* MEmpty *)
    simpl. intros contra. inversion contra.
  - (* MChar*)
    simpl. intros contra. inversion contra. inversion H0.
  - (* MApp *)
    simpl in *. intros h.
    Search (length (?x ++ ?y)).
    rewrite app_length in h.
    Search (?x + ?y <= ?a + ?b).
    apply add_le_cases in h as [H1 | H2].
    * apply IH1 in H1. destruct H1 as [s5 [s6 [s7 [Happ [Hs6  Hm]]]]].
      exists s5, s6, (s7++ s2).
      split.
      + rewrite app_assoc. rewrite app_assoc. rewrite <- (app_assoc T s5 s6 s7).
        rewrite <- Happ. reflexivity.
      + split.
        ++ assumption.
        ++ intros m.
           rewrite app_assoc.
           rewrite app_assoc.
           rewrite <- (app_assoc T s5 _ _).
           apply MApp.
           apply Hm.
           assumption.
    * apply IH2 in H2. destruct H2 as [s5 [s6 [s7 [Happ [Hs6 Hm]]]]].
      exists (s1 ++ s5), s6  , s7.
      split.
      + rewrite <- app_assoc.
        rewrite <- Happ.
        reflexivity.
      + split.
        ++ assumption.
        ++ intros m.
           rewrite <- app_assoc.
           apply MApp.
           assumption.
           apply Hm.
  - (* MUnionL *)
    simpl. intros h. Search (?x + ?y <= ?z).
    apply plus_le in h as [Hle1 Hle2].
    apply IH in Hle1.
    destruct Hle1 as [s2 [s3 [s4 [Happ [Hs3 Hm]]]]].
    exists s2, s3, s4.
    split. assumption. split. assumption.
    intros m. apply MUnionL. apply Hm.
  - (*MUnionR*)
    simpl. intros h. apply plus_le in h as [Hle1 Hle2].
    apply IH in Hle2.
    destruct Hle2 as [s1 [s3 [s4 [Happ [Hs3 Hm]]]]].
    exists s1, s3, s4.
    split. assumption. split. assumption.
    intros m. apply MUnionR. apply Hm.
  - (* MStar0 *)
    simpl. intros h.
    Search (?x <= 0). apply PeanoNat.Nat.le_0_r in h. apply pumping_constant_0_false in h. destruct h.
  - (* MStarApp *)
    simpl in *.
    intros h.
    rewrite app_length in h.
    destruct s1 eqn:E.
    -- apply IH2 in h.
       simpl in *. apply h.
    -- exists [], ( x::l ), s2.
       split. reflexivity.
       split.
       + discriminate.
       + intros m. simpl.
         induction m.
         ++ simpl. assumption.
         ++ apply napp_star. assumption. assumption.
Qed.
(** [] *)

(** **** Exercise: 5 stars, advanced, optional (pumping)

    Now here is the usual version of the pumping lemma. In addition to
    requiring that [s2 <> []], it also requires that [length s1 +
    length s2 <= pumping_constant re]. *)

(*Might be useful??*)
Lemma minimum_string_exists: forall (T: Type) (re: reg_exp T) x, x =~ re -> exists s, s =~ re /\ length s <= Pumping.pumping_constant re.
Proof.
  intros.
  induction H.
  - exists []. simpl. split. apply MEmpty. apply le_S. apply le_n.
  - exists [x]. simpl. split. apply MChar. apply le_S. apply le_n.
  - destruct IHexp_match1 as [s3 [H1s3 H2s3]].
    destruct IHexp_match2 as [s4 [H1s4 H2s4]].
    exists (s3++s4). split. apply MApp. assumption. assumption.
    simpl. rewrite app_length.
    Search (?a + ?b <= ?c + ?d).
    apply PeanoNat.Nat.add_le_mono. assumption. assumption.
  - destruct IHexp_match as [s3 [H1s3 H2s3]].
    exists s3.
    split. apply MUnionL. assumption.
    simpl. apply le_trans with (n:=pumping_constant re1).
    assumption. apply le_plus_l.
  - destruct IHexp_match as [s3 [H1s3 H2s3]].
    exists s3.
    split. apply MUnionR. assumption.
    simpl. apply le_trans with (n:=pumping_constant re2).
    assumption. rewrite add_comm. apply le_plus_l.
  - simpl. exists [].
    split. apply MStar0. simpl. apply O_le_n.
  - destruct IHexp_match1 as [s3 [H1s3 H2s3]].
    destruct IHexp_match2 as [s4 [H1s4 H2s4]].
    exists ( s3 ).
    split. apply MStar1. assumption.
    simpl. assumption.
Qed.

(* TODO: Come back to this later*)
Lemma pumping : forall T (re : reg_exp T) s,
  s =~ re ->
  pumping_constant re <= length s ->
  exists s1 s2 s3,
    s = s1 ++ s2 ++ s3 /\
    s2 <> [] /\
    length s1 + length s2 <= pumping_constant re /\
    forall m, s1 ++ napp m s2 ++ s3 =~ re.

(** You may want to copy your proof of weak_pumping below. *)
Proof.
  intros T re s Hmatch.
  induction Hmatch
    as [ | x | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
       | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
       | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2 ].
  - (* MEmpty *)
    simpl. intros contra. inversion contra.
  - (* MChar*)
    simpl. intros contra. inversion contra. inversion H0.
  - (* MApp *)
    simpl in *. intros h.
    Search (length (?x ++ ?y)).
    rewrite app_length in h.
    Search (?x + ?y <= ?a + ?b).
    apply add_le_cases in h as [H1 | H2].
    * apply IH1 in H1. destruct H1 as [s5 [s6 [s7 [Happ [Hs6  [Hlen Hm]]]]]].
      exists s5, s6, (s7++ s2).
      split.
      + rewrite app_assoc. rewrite app_assoc. rewrite <- (app_assoc T s5 s6 s7).
        rewrite <- Happ. reflexivity.
      + split.
        ++ assumption.
        ++ split.
           +++ apply le_trans with (n:=pumping_constant re1).
               assumption. apply le_plus_l.
           +++ intros m.
               rewrite app_assoc.
               rewrite app_assoc.
               rewrite <- (app_assoc T s5 _ _).
               apply MApp.
               apply Hm.
               assumption.

    (* * admit. *)
    * apply IH2 in H2. destruct H2 as [s5 [s6 [s7 [Happ [Hs6 [Hlen Hm]]]]]].
      exists (s1 ++ s5), s6  , s7.
      split.
      + rewrite <- app_assoc.
        rewrite <- Happ.
        reflexivity.
      + split.
        ++ assumption.
        ++ split.
           +++ rewrite app_length.
               rewrite <- add_assoc.
               Search (?a + ?b <= ?c + ?d).
               apply PeanoNat.Nat.add_le_mono.
               ** admit.
               ** assumption.
           +++ intros m.
               rewrite <- app_assoc.
               apply MApp.
               assumption.
               apply Hm.
  - (* MUnionL *)
    simpl. intros h. Search (?x + ?y <= ?z).
    apply plus_le in h as [Hle1 Hle2].
    apply IH in Hle1.
    destruct Hle1 as [s2 [s3 [s4 [Happ [Hs3 [Hlen Hm]]]]]].
    exists s2, s3, s4.
    split. assumption. split. assumption.
    split.
    apply le_trans with (n:= pumping_constant re1). assumption. apply le_plus_l.
    intros m. apply MUnionL. apply Hm.
  - (*MUnionR*)
    simpl. intros h. apply plus_le in h as [Hle1 Hle2].
    apply IH in Hle2.
    destruct Hle2 as [s1 [s3 [s4 [Happ [Hs3 [Hlen Hm]]]]]].
    exists s1, s3, s4.
    split. assumption. split. assumption.
    split.
    rewrite (add_comm (pumping_constant re1) _).
    apply le_trans with (n:= pumping_constant re2). assumption. apply le_plus_l.
    intros m. apply MUnionR. apply Hm.
  - (* MStar0 *)
    simpl. intros h.
    Search (?x <= 0). apply PeanoNat.Nat.le_0_r in h. apply pumping_constant_0_false in h. destruct h.
  - (* MStarApp *)
    simpl in *.
    intros h.
    rewrite app_length in h.
    destruct s1 eqn:E.
    -- simpl. apply IH2. assumption.
    -- simpl.
       exists [],( (x::l) ++ s2 ),  [].
       simpl.
       split. rewrite app_nil_r. reflexivity.
       split. discriminate.
       split. admit.
       admit.
  (* FILL IN HERE *) Admitted.

End Pumping.
(** [] *)

(* ################################################################# *)
(** * Case Study: Improving Reflection *)

(** We've seen in the [Logic] chapter that we sometimes
    need to relate boolean computations to statements in [Prop].  But
    performing this conversion as we did there can result in tedious
    proof scripts.  Consider the proof of the following theorem: *)

Theorem filter_not_empty_In : forall n l,
  filter (fun x => n =? x) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (n =? m) eqn:H.
    + (* n =? m = true *)
      intros _. rewrite eqb_eq in H. rewrite H.
      left. reflexivity.
    + (* n =? m = false *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** In the first branch after [destruct], we explicitly apply
    the [eqb_eq] lemma to the equation generated by
    destructing [n =? m], to convert the assumption [n =? m
    = true] into the assumption [n = m]; then we had to [rewrite]
    using this assumption to complete the case. *)

(** We can streamline this sort of reasoning by defining an inductive
    proposition that yields a better case-analysis principle for [n =?
    m].  Instead of generating the assumption [(n =? m) = true], which
    usually requires some massaging before we can use it, this
    principle gives us right away the assumption we really need: [n =
    m].

    Following the terminology introduced in [Logic], we call this
    the "reflection principle for equality on numbers," and we say
    that the boolean [n =? m] is _reflected in_ the proposition [n =
    m]. *)

Inductive reflect (P : Prop) : bool -> Prop :=
  | ReflectT (H :   P) : reflect P true
  | ReflectF (H : ~ P) : reflect P false.

(** The [reflect] property takes two arguments: a proposition
    [P] and a boolean [b].  It states that the property [P]
    _reflects_ (intuitively, is equivalent to) the boolean [b]: that
    is, [P] holds if and only if [b = true].

    To see this, notice that, by definition, the only way we can
    produce evidence for [reflect P true] is by showing [P] and then
    using the [ReflectT] constructor.  If we invert this statement,
    this means that we can extract evidence for [P] from a proof of
    [reflect P true].

    Similarly, the only way to show [reflect P false] is by tagging
    evidence for [~ P] with the [ReflectF] constructor. *)

(** To put this observation to work, we first prove that the
    statements [P <-> b = true] and [reflect P b] are indeed
    equivalent.  First, the left-to-right implication: *)

Theorem iff_reflect : forall P b, (P <-> b = true) -> reflect P b.
Proof.
  (* WORKED IN CLASS *)
  intros P b H. destruct b eqn:Eb.
  - apply ReflectT. rewrite H. reflexivity.
  - apply ReflectF. rewrite H. intros H'. discriminate.
Qed.

(** Now you prove the right-to-left implication: *)

(** **** Exercise: 2 stars, standard, especially useful (reflect_iff) *)
Theorem reflect_iff : forall P b, reflect P b -> (P <-> b = true).
Proof.
  intros.
  split.
  + intros.
    destruct b.
    * reflexivity.
    * inversion H. apply H1 in H0. destruct H0.
  + intros.
    destruct b.
    * inversion H. assumption.
    * discriminate.
Qed.
(** [] *)

(** We can think of [reflect] as a variant of the usual "if and only
    if" connective; the advantage of [reflect] is that, by destructing
    a hypothesis or lemma of the form [reflect P b], we can perform
    case analysis on [b] while _at the same time_ generating
    appropriate hypothesis in the two branches ([P] in the first
    subgoal and [~ P] in the second). *)

(** Let's use [reflect] to produce a smoother proof of
    [filter_not_empty_In].

    We begin by recasting the [eqb_eq] lemma in terms of [reflect]: *)

Lemma eqbP : forall n m, reflect (n = m) (n =? m).
Proof.
  intros n m. apply iff_reflect. rewrite eqb_eq. reflexivity.
Qed.

(** The proof of [filter_not_empty_In] now goes as follows.  Notice
    how the calls to [destruct] and [rewrite] in the earlier proof of
    this theorem are combined here into a single call to
    [destruct]. *)

(** (To see this clearly, execute the two proofs of
    [filter_not_empty_In] with Coq and observe the differences in
    proof state at the beginning of the first case of the
    [destruct].) *)

Theorem filter_not_empty_In' : forall n l,
  filter (fun x => n =? x) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (eqbP n m) as [H | H].
    + (* n = m *)
      intros _. rewrite H. left. reflexivity.
    + (* n <> m *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** **** Exercise: 3 stars, standard, especially useful (eqbP_practice)

    Use [eqbP] as above to prove the following: *)

Fixpoint count n l :=
  match l with
  | [] => 0
  | m :: l' => (if n =? m then 1 else 0) + count n l'
  end.

Theorem eqbP_practice : forall n l,
  count n l = 0 -> ~(In n l).
Proof.
  intros n l Hcount. induction l as [| m l' IHl'].
  - simpl. intros contra. destruct contra.
  - simpl in *.
    destruct (eqbP n m) as [H | H].
    + rewrite H in *. simpl in *.  discriminate.
    + simpl in *.
      intros [H1 | H2].
      symmetry in H1. apply H in H1. inversion H1.
      apply IHl'. assumption. assumption.
Qed.
(** [] *)

(** This small example shows reflection giving us a small gain in
    convenience; in larger developments, using [reflect] consistently
    can often lead to noticeably shorter and clearer proof scripts.
    We'll see many more examples in later chapters and in _Programming
    Language Foundations_.

    This way of using [reflect] was popularized by _SSReflect_, a Coq
    library that has been used to formalize important results in
    mathematics, including the 4-color theorem and the Feit-Thompson
    theorem.  The name SSReflect stands for _small-scale reflection_,
    i.e., the pervasive use of reflection to streamline small proof
    steps by turning them into boolean computations. *)

(* ################################################################# *)
(** * Additional Exercises *)

(** **** Exercise: 3 stars, standard, especially useful (nostutter_defn)

    Formulating inductive definitions of properties is an important
    skill you'll need in this course.  Try to solve this exercise
    without any help.

    We say that a list "stutters" if it repeats the same element
    consecutively.  (This is different from not containing duplicates:
    the sequence [[1;4;1]] has two occurrences of the element [1] but
    does not stutter.)  The property "[nostutter mylist]" means that
    [mylist] does not stutter.  Formulate an inductive definition for
    [nostutter]. *)

Inductive nostutter {X:Type} : list X -> Prop :=
  | c_nil : nostutter []
  | c_single (hd:X) : nostutter [hd]
  | c_larger (hd1: X) (hd2:X) (Hneq: hd1 <> hd2) (l: list X) : nostutter (hd2::l ) -> nostutter (hd1::hd2::l)
.
(** Make sure each of these tests succeeds, but feel free to change
    the suggested proof (in comments) if the given one doesn't work
    for you.  Your definition might be different from ours and still
    be correct, in which case the examples might need a different
    proof.  (You'll notice that the suggested proofs use a number of
    tactics we haven't talked about, to make them more robust to
    different possible ways of defining [nostutter].  You can probably
    just uncomment and use them as-is, but you can also prove each
    example with more basic tactics.)  *)

Example test_nostutter_1: nostutter [3;1;4;1;5;6].
(* Proof. simpl. *)
(*        apply c_larger. discriminate. *)
(*        apply c_larger. discriminate. *)
(*        apply c_larger. discriminate. *)
(*        apply c_larger. discriminate. *)
(*        apply c_larger. discriminate. *)
(*        apply c_single. *)
(* Qed. *)

  Proof. repeat constructor; apply eqb_neq; auto.
  Qed.

Example test_nostutter_2:  nostutter (@nil nat).
(* Proof. *)
(*   apply c_nil. *)
(* Qed. *)

  Proof. repeat constructor; apply eqb_neq; auto.
  Qed.

Example test_nostutter_3:  nostutter [5].
(*   apply c_single. *)
(* Qed. *)

  Proof. repeat constructor; auto. Qed.

Example test_nostutter_4:      not (nostutter [3;1;1;4]).
(*   intros h. *)
(*   inversion h. *)
(*   inversion H0. *)
(*   destruct Hneq0. reflexivity. *)
(* Qed. *)

  Proof. intro.
  repeat match goal with
    h: nostutter _ |- _ => inversion h; clear h; subst
  end.
  contradiction; auto. Qed.

(* Do not modify the following line: *)
Definition manual_grade_for_nostutter : option (nat*string) := None.
(** [] *)

(** **** Exercise: 4 stars, advanced (filter_challenge)

    Let's prove that our definition of [filter] from the [Poly]
    chapter matches an abstract specification.  Here is the
    specification, written out informally in English:

    A list [l] is an "in-order merge" of [l1] and [l2] if it contains
    all the same elements as [l1] and [l2], in the same order as [l1]
    and [l2], but possibly interleaved.  For example,

    [1;4;6;2;3]

    is an in-order merge of

    [1;6;2]

    and

    [4;3].

    Now, suppose we have a set [X], a function [test: X->bool], and a
    list [l] of type [list X].  Suppose further that [l] is an
    in-order merge of two lists, [l1] and [l2], such that every item
    in [l1] satisfies [test] and no item in [l2] satisfies test.  Then
    [filter test l = l1].

    First define what it means for one list to be a merge of two
    others.  Do this with an inductive relation, not a [Fixpoint].  *)

Inductive merge {X:Type} : list X -> list X -> list X -> Prop :=
  | merge_nil : merge [] [] []
  | merge_l (l: list X) : merge l [] l
  | merge_r (r: list X) : merge [] r r
  | merge_interleaved (hd1:X ) (hd2:X) (tl1 tl2 merged_tl: list X) (Htl: merge tl1 tl2 merged_tl) : merge (hd1::tl1) (hd2::tl2) (hd1::hd2::merged_tl)
(* FILL IN HERE *)
.

Theorem merge_filter : forall (X : Set) (test: X->bool) (l l1 l2 : list X),
  merge l1 l2 l ->
  All (fun n => test n = true) l1 ->
  All (fun n => test n = false) l2 ->
  filter test l = l1.
Proof.
  intros.
  induction H.
  * reflexivity.
  * simpl in *.
    induction l.
    reflexivity.
    simpl in H0.
    destruct H0 as [Hx Hl].
    simpl. rewrite Hx. apply IHl in Hl. rewrite Hl. reflexivity.
  * simpl in *.
    induction r.
    reflexivity.
    simpl in H1.
    destruct H1 as [Hx Hl].
    simpl. rewrite Hx. apply IHr. assumption.
  * simpl in *.
    destruct H0 as [Hhd1 Htl1].
    destruct H1 as [Hhd2 Htl2].
    rewrite Hhd1. rewrite Hhd2.
    apply IHmerge in Htl1. rewrite Htl1. reflexivity.
    assumption.
Qed.

(* FILL IN HERE *)

(** [] *)

(** **** Exercise: 5 stars, advanced, optional (filter_challenge_2)

    A different way to characterize the behavior of [filter] goes like
    this: Among all subsequences of [l] with the property that [test]
    evaluates to [true] on all their members, [filter test l] is the
    longest.  Formalize this claim and prove it. *)

(* NOTE: SKIPPING THIS BECAUSE 5 Star optional ones will mess with my brain for a long time*)
(* FILL IN HERE

    [] *)

(** **** Exercise: 4 stars, standard, optional (palindromes)

    A palindrome is a sequence that reads the same backwards as
    forwards.

    - Define an inductive proposition [pal] on [list X] that
      captures what it means to be a palindrome. (Hint: You'll need
      three cases.  Your definition should be based on the structure
      of the list; just having a single constructor like

        c : forall l, l = rev l -> pal l

      may seem obvious, but will not work very well.)

    - Prove ([pal_app_rev]) that

       forall l, pal (l ++ rev l).

    - Prove ([pal_rev] that)

       forall l, pal l -> l = rev l.
*)

Inductive pal {X:Type} : list X -> Prop :=
  | pal_nil : pal []
  | pal_single (x:X): pal [x]
  | pal_surround (x: X) (l: list X) : pal l -> pal ([x] ++ l ++ [x])
(* FILL IN HERE *)
.

Theorem pal_app_rev : forall (X:Type) (l : list X),
  pal (l ++ (rev l)).
Proof.
  intros.
  induction l.
  - simpl. apply pal_nil.
  - simpl. rewrite cons_is_hd_app_tl.
    rewrite app_assoc. rewrite app_assoc.
    rewrite <- (app_assoc X [x] l _).
    rewrite <- cons_is_hd_app_tl.
    apply pal_surround. assumption.
Qed.

Theorem pal_rev : forall (X:Type) (l: list X) , pal l -> l = rev l.
Proof.
  intros.
  induction H.
  - reflexivity.
  - reflexivity.
  - simpl.
    Search rev.
    rewrite rev_app_distr.
    simpl.
    rewrite <- IHpal. reflexivity.
Qed.
(** [] *)

(** **** Exercise: 5 stars, standard, optional (palindrome_converse)

    Again, the converse direction is significantly more difficult, due
    to the lack of evidence.  Using your definition of [pal] from the
    previous exercise, prove that

     forall l, l = rev l -> pal l.
*)

Lemma rev_middle: forall {X: Type} (l1: list X) (l2:list X), l1++ l2 = rev (l1 ++ l2) /\ l1 = rev l1 ->
    exists l', l1 ++ l' ++ l1 = rev (l1 ++ l' ++ l1).
  intros.
  generalize dependent l1.
  induction l2.
  - exists []. destruct H as [H1 H2]. simpl. rewrite rev_app_distr. rewrite <-H2. reflexivity.
  - intros l1 H.
    simpl in *.
    specialize IHl2 with (l1:=(l1)).
    rewrite cons_is_hd_app_tl in H.
    destruct H as [H1 H2].
    exists [x].
    rewrite rev_app_distr. rewrite rev_app_distr.
    rewrite <-H2. simpl.
    rewrite <- app_assoc.
    reflexivity.
Qed.

Lemma same_length : forall {X:Type} (hd:X) (tl l: list X) , length (hd::tl) = length l -> exists hd' tl', l = hd'::tl' /\ length tl' = length tl.
  intros.
  induction l.
  - discriminate H.
  - simpl in H. injection H as Hlen.
    exists x, l.
    split.
    reflexivity.
    symmetry.
    assumption.
Qed.

Lemma prefix_app_eq : forall {X: Type} {l1 l2 l3: list X}, l1 ++ l2 = l1 ++ l3 /\  length l2 = length l3 -> l2 = l3.

  intros X l1.
  induction l1.
  * intros l2 l3 [H1 H2].
    simpl in *.
    assumption.
  * intros l2 l3 [H1 H2].
    simpl in *.
    injection H1 as H1'.
    apply IHl1.
    split. assumption. assumption.
Qed.

Lemma rev_middle': forall {X: Type} (l1: list X) (l2:list X), l1++ l2 = rev (l1 ++ l2) /\ l1 = rev l1 ->
    exists l' , l1 ++ l2 = l1 ++ l' ++ rev l1  \/ l1 ++ l2 = l1.
  intros.
  generalize dependent l1.
  induction l2.
  -  exists []. destruct H as [H1 H2]. simpl. right. rewrite app_nil_r. reflexivity.
  - simpl in *.
    intros.
    (* destruct H as [H1 H2]. *)
    rewrite cons_is_hd_app_tl in H.
    admit.
Admitted.

(* Lemma rev_same_with_atleast_one_elem : forall {X:Type} (l: list X) (hd: X), *)
(*   hd::l = rev (hd::l) -> l = [] \/ (exists l', l' = rev l' /\ hd::l = hd::l' ++ [ hd ] ). *)
(*   intros. *)
(*   destruct (rev (hd::l)) eqn:E. *)
(*   - discriminate H. *)
(*   - injection H as H1 H2. *)
(*     induction l (* eqn:E' *). *)
(*     * left. reflexivity. *)
(*     * right. (* rewrite <- (rev_involutive X (hd::x0::l1)). *) *)
(*       (* rewrite E. *) *)
(*       rewrite H1 in *. *)
(*       simpl in *. *)
(*       exists (x0:: rev l1 ++ [x0]). *)
(*       rewrite cons_is_hd_app_tl. *)
(*       rewrite rev_app_distr. *)
(*       rewrite rev_app_distr. *)
(*       rewrite rev_involutive. *)
(*       split. *)
(*       + rewrite app_assoc. simpl. *)
(* Qed. *)

Theorem palindrome_converse: forall {X: Type} (l: list X),
    l = rev l -> pal l.
Proof.
  intros X l.
  induction l.
  - intros . apply pal_nil.
  - intros.
    simpl in *.
    destruct (rev l) eqn:E.
    * rewrite H. simpl. apply pal_single.
    * rewrite H.
      rewrite cons_is_hd_app_tl.
      rewrite <- app_assoc.
      injection H as H1 H2.
      rewrite <- H1.
      apply pal_surround.
      admit.
  (* FILL IN HERE *) Admitted.


(** **** Exercise: 4 stars, advanced, optional (NoDup)

    Recall the definition of the [In] property from the [Logic]
    chapter, which asserts that a value [x] appears at least once in a
    list [l]: *)

(* Fixpoint In (A : Type) (x : A) (l : list A) : Prop :=
   match l with
   | [] => False
   | x' :: l' => x' = x \/ In A x l'
   end *)

(** Your first task is to use [In] to define a proposition [disjoint X
    l1 l2], which should be provable exactly when [l1] and [l2] are
    lists (with elements of type X) that have no elements in
    common. *)

(* FILL IN HERE *)

(** Next, use [In] to define an inductive proposition [NoDup X
    l], which should be provable exactly when [l] is a list (with
    elements of type [X]) where every member is different from every
    other.  For example, [NoDup nat [1;2;3;4]] and [NoDup
    bool []] should be provable, while [NoDup nat [1;2;1]] and
    [NoDup bool [true;true]] should not be.  *)

(* FILL IN HERE *)

(** Finally, state and prove one or more interesting theorems relating
    [disjoint], [NoDup] and [++] (list append).  *)

(* FILL IN HERE *)

(* Do not modify the following line: *)
Definition manual_grade_for_NoDup_disjoint_etc : option (nat*string) := None.
(** [] *)

(** **** Exercise: 4 stars, advanced, optional (pigeonhole_principle)

    The _pigeonhole principle_ states a basic fact about counting: if
    we distribute more than [n] items into [n] pigeonholes, some
    pigeonhole must contain at least two items.  As often happens, this
    apparently trivial fact about numbers requires non-trivial
    machinery to prove, but we now have enough... *)

(** First prove an easy and useful lemma. *)

Lemma in_split : forall (X:Type) (x:X) (l:list X),
  In x l ->
  exists l1 l2, l = l1 ++ x :: l2.
Proof.
  (* FILL IN HERE *) Admitted.

(** Now define a property [repeats] such that [repeats X l] asserts
    that [l] contains at least one repeated element (of type [X]).  *)

Inductive repeats {X:Type} : list X -> Prop :=
  (* FILL IN HERE *)
.

(* Do not modify the following line: *)
Definition manual_grade_for_check_repeats : option (nat*string) := None.

(** Now, here's a way to formalize the pigeonhole principle.  Suppose
    list [l2] represents a list of pigeonhole labels, and list [l1]
    represents the labels assigned to a list of items.  If there are
    more items than labels, at least two items must have the same
    label -- i.e., list [l1] must contain repeats.

    This proof is much easier if you use the [excluded_middle]
    hypothesis to show that [In] is decidable, i.e., [forall x l, (In x
    l) \/ ~ (In x l)].  However, it is also possible to make the proof
    go through _without_ assuming that [In] is decidable; if you
    manage to do this, you will not need the [excluded_middle]
    hypothesis. *)
Theorem pigeonhole_principle: excluded_middle ->
  forall (X:Type) (l1  l2:list X),
  (forall x, In x l1 -> In x l2) ->
  length l2 < length l1 ->
  repeats l1.
Proof.
  intros EM X l1. induction l1 as [|x l1' IHl1'].
  (* FILL IN HERE *) Admitted.
(** [] *)

(* ================================================================= *)
(** ** Extended Exercise: A Verified Regular-Expression Matcher *)

(** We have now defined a match relation over regular expressions and
    polymorphic lists. We can use such a definition to manually prove that
    a given regex matches a given string, but it does not give us a
    program that we can run to determine a match automatically.

    It would be reasonable to hope that we can translate the definitions
    of the inductive rules for constructing evidence of the match relation
    into cases of a recursive function that reflects the relation by recursing
    on a given regex. However, it does not seem straightforward to define
    such a function in which the given regex is a recursion variable
    recognized by Coq. As a result, Coq will not accept that the function
    always terminates.

    Heavily-optimized regex matchers match a regex by translating a given
    regex into a state machine and determining if the state machine
    accepts a given string. However, regex matching can also be
    implemented using an algorithm that operates purely on strings and
    regexes without defining and maintaining additional datatypes, such as
    state machines. We'll implement such an algorithm, and verify that
    its value reflects the match relation. *)

(** We will implement a regex matcher that matches strings represented
    as lists of ASCII characters: *)
Require Import Coq.Strings.Ascii.

Definition string := list ascii.

(** The Coq standard library contains a distinct inductive definition
    of strings of ASCII characters. However, we will use the above
    definition of strings as lists as ASCII characters in order to apply
    the existing definition of the match relation.

    We could also define a regex matcher over polymorphic lists, not lists
    of ASCII characters specifically. The matching algorithm that we will
    implement needs to be able to test equality of elements in a given
    list, and thus needs to be given an equality-testing
    function. Generalizing the definitions, theorems, and proofs that we
    define for such a setting is a bit tedious, but workable. *)

(** The proof of correctness of the regex matcher will combine
    properties of the regex-matching function with properties of the
    [match] relation that do not depend on the matching function. We'll go
    ahead and prove the latter class of properties now. Most of them have
    straightforward proofs, which have been given to you, although there
    are a few key lemmas that are left for you to prove. *)

(** Each provable [Prop] is equivalent to [True]. *)
Lemma provable_equiv_true : forall (P : Prop), P -> (P <-> True).
Proof.
  intros.
  split.
  - intros. constructor.
  - intros _. apply H.
Qed.

(** Each [Prop] whose negation is provable is equivalent to [False]. *)
Lemma not_equiv_false : forall (P : Prop), ~P -> (P <-> False).
Proof.
  intros.
  split.
  - apply H.
  - intros. destruct H0.
Qed.

(** [EmptySet] matches no string. *)
Lemma null_matches_none : forall (s : string), (s =~ EmptySet) <-> False.
Proof.
  intros.
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [EmptyStr] only matches the empty string. *)
Lemma empty_matches_eps : forall (s : string), s =~ EmptyStr <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MEmpty.
Qed.

(** [EmptyStr] matches no non-empty string. *)
Lemma empty_nomatch_ne : forall (a : ascii) s, (a :: s =~ EmptyStr) <-> False.
Proof.
  intros.
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [Char a] matches no string that starts with a non-[a] character. *)
Lemma char_nomatch_char :
  forall (a b : ascii) s, b <> a -> (b :: s =~ Char a <-> False).
Proof.
  intros.
  apply not_equiv_false.
  unfold not.
  intros.
  apply H.
  inversion H0.
  reflexivity.
Qed.

(** If [Char a] matches a non-empty string, then the string's tail is empty. *)
Lemma char_eps_suffix : forall (a : ascii) s, a :: s =~ Char a <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MChar.
Qed.

(** [App re0 re1] matches string [s] iff [s = s0 ++ s1], where [s0]
    matches [re0] and [s1] matches [re1]. *)
Lemma app_exists : forall (s : string) re0 re1,
  s =~ App re0 re1 <->
  exists s0 s1, s = s0 ++ s1 /\ s0 =~ re0 /\ s1 =~ re1.
Proof.
  intros.
  split.
  - intros. inversion H. exists s1, s2. split.
    * reflexivity.
    * split. apply H3. apply H4.
  - intros [ s0 [ s1 [ Happ [ Hmat0 Hmat1 ] ] ] ].
    rewrite Happ. apply (MApp s0 _ s1 _ Hmat0 Hmat1).
Qed.

(** **** Exercise: 3 stars, standard, optional (app_ne)

    [App re0 re1] matches [a::s] iff [re0] matches the empty string
    and [a::s] matches [re1] or [s=s0++s1], where [a::s0] matches [re0]
    and [s1] matches [re1].

    Even though this is a property of purely the match relation, it is a
    critical observation behind the design of our regex matcher. So (1)
    take time to understand it, (2) prove it, and (3) look for how you'll
    use it later. *)
Lemma app_ne : forall (a : ascii) s re0 re1,
  a :: s =~ (App re0 re1) <->
  ([ ] =~ re0 /\ a :: s =~ re1) \/
  exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re0 /\ s1 =~ re1.
Proof.
  (* FILL IN HERE *) Admitted.
(** [] *)

(** [s] matches [Union re0 re1] iff [s] matches [re0] or [s] matches [re1]. *)
Lemma union_disj : forall (s : string) re0 re1,
  s =~ Union re0 re1 <-> s =~ re0 \/ s =~ re1.
Proof.
  intros. split.
  - intros. inversion H.
    + left. apply H2.
    + right. apply H1.
  - intros [ H | H ].
    + apply MUnionL. apply H.
    + apply MUnionR. apply H.
Qed.

(** **** Exercise: 3 stars, standard, optional (star_ne)

    [a::s] matches [Star re] iff [s = s0 ++ s1], where [a::s0] matches
    [re] and [s1] matches [Star re]. Like [app_ne], this observation is
    critical, so understand it, prove it, and keep it in mind.

    Hint: you'll need to perform induction. There are quite a few
    reasonable candidates for [Prop]'s to prove by induction. The only one
    that will work is splitting the [iff] into two implications and
    proving one by induction on the evidence for [a :: s =~ Star re]. The
    other implication can be proved without induction.

    In order to prove the right property by induction, you'll need to
    rephrase [a :: s =~ Star re] to be a [Prop] over general variables,
    using the [remember] tactic.  *)

Lemma star_ne : forall (a : ascii) s re,
  a :: s =~ Star re <->
  exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re /\ s1 =~ Star re.
Proof.
  (* FILL IN HERE *) Admitted.
(** [] *)

(** The definition of our regex matcher will include two fixpoint
    functions. The first function, given regex [re], will evaluate to a
    value that reflects whether [re] matches the empty string. The
    function will satisfy the following property: *)
Definition refl_matches_eps m :=
  forall re : reg_exp ascii, reflect ([ ] =~ re) (m re).

(** **** Exercise: 2 stars, standard, optional (match_eps)

    Complete the definition of [match_eps] so that it tests if a given
    regex matches the empty string: *)
Fixpoint match_eps (re: reg_exp ascii) : bool
  (* REPLACE THIS LINE WITH ":= _your_definition_ ." *). Admitted.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (match_eps_refl)

    Now, prove that [match_eps] indeed tests if a given regex matches
    the empty string.  (Hint: You'll want to use the reflection lemmas
    [ReflectT] and [ReflectF].) *)
Lemma match_eps_refl : refl_matches_eps match_eps.
Proof.
  (* FILL IN HERE *) Admitted.
(** [] *)

(** We'll define other functions that use [match_eps]. However, the
    only property of [match_eps] that you'll need to use in all proofs
    over these functions is [match_eps_refl]. *)

(** The key operation that will be performed by our regex matcher will
    be to iteratively construct a sequence of regex derivatives. For each
    character [a] and regex [re], the derivative of [re] on [a] is a regex
    that matches all suffixes of strings matched by [re] that start with
    [a]. I.e., [re'] is a derivative of [re] on [a] if they satisfy the
    following relation: *)

Definition is_der re (a : ascii) re' :=
  forall s, a :: s =~ re <-> s =~ re'.

(** A function [d] derives strings if, given character [a] and regex
    [re], it evaluates to the derivative of [re] on [a]. I.e., [d]
    satisfies the following property: *)
Definition derives d := forall a re, is_der re a (d a re).

(** **** Exercise: 3 stars, standard, optional (derive)

    Define [derive] so that it derives strings. One natural
    implementation uses [match_eps] in some cases to determine if key
    regex's match the empty string. *)
Fixpoint derive (a : ascii) (re : reg_exp ascii) : reg_exp ascii
  (* REPLACE THIS LINE WITH ":= _your_definition_ ." *). Admitted.
(** [] *)

(** The [derive] function should pass the following tests. Each test
    establishes an equality between an expression that will be
    evaluated by our regex matcher and the final value that must be
    returned by the regex matcher. Each test is annotated with the
    match fact that it reflects. *)
Example c := ascii_of_nat 99.
Example d := ascii_of_nat 100.

(** "c" =~ EmptySet: *)
Example test_der0 : match_eps (derive c (EmptySet)) = false.
Proof.
  (* FILL IN HERE *) Admitted.

(** "c" =~ Char c: *)
Example test_der1 : match_eps (derive c (Char c)) = true.
Proof.
  (* FILL IN HERE *) Admitted.

(** "c" =~ Char d: *)
Example test_der2 : match_eps (derive c (Char d)) = false.
Proof.
  (* FILL IN HERE *) Admitted.

(** "c" =~ App (Char c) EmptyStr: *)
Example test_der3 : match_eps (derive c (App (Char c) EmptyStr)) = true.
Proof.
  (* FILL IN HERE *) Admitted.

(** "c" =~ App EmptyStr (Char c): *)
Example test_der4 : match_eps (derive c (App EmptyStr (Char c))) = true.
Proof.
  (* FILL IN HERE *) Admitted.

(** "c" =~ Star c: *)
Example test_der5 : match_eps (derive c (Star (Char c))) = true.
Proof.
  (* FILL IN HERE *) Admitted.

(** "cd" =~ App (Char c) (Char d): *)
Example test_der6 :
  match_eps (derive d (derive c (App (Char c) (Char d)))) = true.
Proof.
  (* FILL IN HERE *) Admitted.

(** "cd" =~ App (Char d) (Char c): *)
Example test_der7 :
  match_eps (derive d (derive c (App (Char d) (Char c)))) = false.
Proof.
  (* FILL IN HERE *) Admitted.

(** **** Exercise: 4 stars, standard, optional (derive_corr)

    Prove that [derive] in fact always derives strings.

    Hint: one proof performs induction on [re], although you'll need
    to carefully choose the property that you prove by induction by
    generalizing the appropriate terms.

    Hint: if your definition of [derive] applies [match_eps] to a
    particular regex [re], then a natural proof will apply
    [match_eps_refl] to [re] and destruct the result to generate cases
    with assumptions that the [re] does or does not match the empty
    string.

    Hint: You can save quite a bit of work by using lemmas proved
    above. In particular, to prove many cases of the induction, you
    can rewrite a [Prop] over a complicated regex (e.g., [s =~ Union
    re0 re1]) to a Boolean combination of [Prop]'s over simple
    regex's (e.g., [s =~ re0 \/ s =~ re1]) using lemmas given above
    that are logical equivalences. You can then reason about these
    [Prop]'s naturally using [intro] and [destruct]. *)
Lemma derive_corr : derives derive.
Proof.
  (* FILL IN HERE *) Admitted.
(** [] *)

(** We'll define the regex matcher using [derive]. However, the only
    property of [derive] that you'll need to use in all proofs of
    properties of the matcher is [derive_corr]. *)

(** A function [m] _matches regexes_ if, given string [s] and regex [re],
    it evaluates to a value that reflects whether [s] is matched by
    [re]. I.e., [m] holds the following property: *)
Definition matches_regex m : Prop :=
  forall (s : string) re, reflect (s =~ re) (m s re).

(** **** Exercise: 2 stars, standard, optional (regex_match)

    Complete the definition of [regex_match] so that it matches
    regexes. *)
Fixpoint regex_match (s : string) (re : reg_exp ascii) : bool
  (* REPLACE THIS LINE WITH ":= _your_definition_ ." *). Admitted.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (regex_match_correct)

    Finally, prove that [regex_match] in fact matches regexes.

    Hint: if your definition of [regex_match] applies [match_eps] to
    regex [re], then a natural proof applies [match_eps_refl] to [re]
    and destructs the result to generate cases in which you may assume
    that [re] does or does not match the empty string.

    Hint: if your definition of [regex_match] applies [derive] to
    character [x] and regex [re], then a natural proof applies
    [derive_corr] to [x] and [re] to prove that [x :: s =~ re] given
    [s =~ derive x re], and vice versa. *)
Theorem regex_match_correct : matches_regex regex_match.
Proof.
  (* FILL IN HERE *) Admitted.
(** [] *)

(* 2023-10-03 16:40 *)
