-- import Mathlib.Tactic.Common
-- import Mathlib.Control.Random
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Pi

/-!
  # The Foundational Cryptographic Framework (FCF)

  This is a port from the FCF library in Coq to Lean. We make no attempt at completeness, rather we only port enough for our goal of mechanizing proof systems.
-/


namespace Crypto

section Comp

-- Probabilistic computation
inductive Comp : Type _ → Type _ where
  -- return a value of type A
  | pure [DecidableEq A] : A → Comp A
  -- continue the computation
  | bind : Comp B → (B → Comp A) → Comp A
  -- sample uniformly among some non-empty finite type with decidable equality
  | rand [Fintype A] [Inhabited A] [DecidableEq A] : Comp A
  -- repeat until some deciable predicate returns true
  | repeat : Comp A → (A → Bool) → Comp A

-- Can't define monad instance since `DecidableEq` gets in the way
-- instance : Monad Comp where
--   pure := Comp.pure
--   bind := Comp.bind

@[simp]
def compExists {A : Type _} (x : Comp A) : A :=
  match x with
    | Comp.pure y => y
    | Comp.bind y f => compExists (f (compExists y))
    | Comp.rand => default
    | Comp.repeat y _ => compExists y

instance compDecidableEq {A : Type _} (x : Comp A) : DecidableEq A :=
  match x with
    | Comp.pure _ => inferInstance
    | Comp.bind y f => compDecidableEq (f (compExists y))
    | Comp.rand => inferInstance
    | Comp.repeat y _ => compDecidableEq y

instance compBindDecidableEq {A B : Type _} (x : Comp B) (f : B → Comp A) : DecidableEq A :=
  compDecidableEq (Comp.bind x f)


def test (s : Set A) (f : A → Set B) : Set B := { b | ∃ a ∈ s, b ∈ f a }

-- def test2 (s : Finset A) (f : A → Finset B) : Finset B := { b | ∃ a ∈ s, b ∈ f a }

#check Finset.biUnion

def getSupport {A : Type _} (x : Comp A) : Finset A :=
  match x with
    | Comp.pure y => {y}
    | Comp.bind y f => @Finset.biUnion _ _ (compBindDecidableEq y f) (getSupport y) (getSupport ∘ f)
    | Comp.rand => Finset.univ
    | Comp.repeat y _ => getSupport y
-- termination_by sizeOf x => sorry

inductive wellFormedComp {A : Type _} : Comp A → Prop where
  | wfPure [DecidableEq A] : wellFormedComp (Comp.pure x)
  | wfBind : (x : Comp B) → (f : B → Comp A) → wellFormedComp (Comp.bind x f) -- add more conditions
  | wfRand [Fintype A] [Inhabited A] [DecidableEq A] : wellFormedComp Comp.rand
  | wfRepeat [DecidableEq A] : (x : Comp A) → (p : A → Bool) → (∀ b, wellFormedComp x → b ∈ Finset.filter p (getSupport x)) → wellFormedComp (Comp.repeat x p)


end Comp


section CompEq

-- Syntactic equality for `Comp`
inductive CompEq : Comp A → Comp A → Prop where
  | eqPure [DecidableEq A] : CompEq (@Comp.pure A _ x) (@Comp.pure A _ x)
  | eqBind : CompEq x y → (∀ b, CompEq (f b) (g b)) → CompEq (Comp.bind x f) (Comp.bind y g)
  | eqRand [Fintype A] [Inhabited A] [DecidableEq A] : CompEq (@Comp.rand A _ _ _) (@Comp.rand A _ _ _)
  | eqRepeat : CompEq x y → (∀ a, p a = q a) → CompEq (Comp.repeat x p) (Comp.repeat y q)

@[simp]
theorem comp_eq_refl (x : Comp A) : CompEq x x := match x with
  | Comp.pure _ => CompEq.eqPure
  | Comp.bind x f => CompEq.eqBind (comp_eq_refl x) (λ b => comp_eq_refl (f b))
  | Comp.rand => CompEq.eqRand
  | Comp.repeat x _ => CompEq.eqRepeat (comp_eq_refl x) (λ _ => rfl)




end CompEq


section OComp

-- Probabilistic computation with access to a stateful oracle
inductive OComp : Type _ → Type _ → Type _ → Type _ where
  -- give oracle access to some probabilistic computation
  | pure : Comp C → OComp A B C
  -- continue the oracle computation
  | bind : OComp A B C → (C → OComp A B C') → OComp A B C'
  -- query the oracle with query of type `A`, and get the result of type `B`
  | query : A → OComp A B B
  -- run the program under a different oracle that is allowed to access the current oracle
  | run : OComp A B C → S → (S → A → OComp A' B' (B × S)) → OComp A' B' (C × S)

-- instance : Monad (OComp A B) where
--   pure := OComp.pure ∘ Comp.pure
--   bind := OComp.bind




end OComp

end Crypto


-- other stuff from call with Josh

-- Probability trees
inductive PTree : Type → Type where
  | return : A → PTree A
  | flip : (Bool → PTree A) → PTree A

-- Interaction trees
inductive ITree (E : Type _ → Type _) (R : Type _) : Type _ where
  | ret : R → ITree E R
  | tau : ITree E R → ITree E R
  | event : (E A) → (A → ITree E R) → ITree E R

-- can we simplify this to a single monadic computation
-- return / flip random coin / query oracles

-- query (O : Oracle) (O.Input : Type) → (O.Output : Type)

-- interaction trees in Coq:
-- computations are indexed by effects / oracles

-- how to argue that model is reasonable?
-- already have an implementation somewhere else, write another impl in Lean, then check they're the same on random inputs (include lots of test vectors)

-- write a model of the proof system that's parametrized by an oracle
-- prove that when it's the random oracle, then it's secure
-- then test for equivalence when it's instantiated with a concrete hash function

-- Use good support for Monad Transformer : StateT PMF α

-- EasyCrypt: program logic for proving equivalence of crypto programs
-- Need something similar here (Hoare logic), see what FCF does
-- If p is true before running the program, then q is true after running the program. Show this is true for probabilistic programs.

-- `PMF` is the denotation but not the semantics
-- Need a concrete execution model
-- A simple model: define it as a tre

-- basically an interaction tree, except that oracle is fixed to flipping a random coin

-- Gen: PTree F  randomly sample a field element
--

-- General library for crypto reasoning in Lean?
-- Coq is way more mature, proof automation is better than Lean right now
-- Lean has `Mathlib`,
-- Doing things fully foundationally is nice, but it makes it more difficult to use
