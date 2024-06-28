import Mathlib.FieldTheory.Tower
import Mathlib.FieldTheory.Finite.GaloisField
import Mathlib.RingTheory.Adjoin.Basic
-- import Mathlib.Algebra.Polynomial.Basic

/-!
# Binary Tower Field

Define the binary tower field GF(2^{2^k}) as an iterated quadratic extension of GF(2).

-/


noncomputable section

open Polynomial

notation:10 "GF(" term:10 ")" => GaloisField term 1

-- TODO: consider bundling all the fields below into just one structure, and then make the instances inside accessible. Example from R1CS:
/-
-- Bundle R and its CommSemiring instance
structure RingParams where
  R : Type _
  [commSemiring : CommSemiring R]

-- Make the CommSemiring instance accessible
attribute [instance] RingParams.commSemiring
-/

-- In this definition, the field defined by (AbstractBinaryTower k) corresponds to GF(2^{2^{k-1}})
def AbstractBinaryTower (k : ℕ) : (F : Type _) × (List F) × (CommRing F) × (Inhabited F) :=
  match k with
  | 0 => ⟨ GF(2), [(1 : GF(2))], inferInstance, inferInstance ⟩
  | k + 1 =>
    let ⟨ F, elts, _, _ ⟩ := AbstractBinaryTower k
    let currX : F := elts.getLastI
    let newPoly : Polynomial F := X^2 + (C currX) * X + 1
    let newF := AdjoinRoot newPoly
    let newX := AdjoinRoot.root newPoly
    let newElts := elts.map (fun x => (AdjoinRoot.of newPoly).toFun x)
    ⟨ newF, newElts ++ [newX], inferInstance, inferInstance ⟩

namespace AbstractBinaryTower

@[simp]
def field (k : ℕ) := (AbstractBinaryTower k).1

@[simp]
instance CommRing (k : ℕ) : CommRing (field k) := (AbstractBinaryTower k).2.2.1

@[simp]
instance Inhabited (k : ℕ) : Inhabited (field k) := (AbstractBinaryTower k).2.2.2

@[simp]
def list (k : ℕ) : List (field k):= (AbstractBinaryTower k).2.1

@[simp]
def poly (k : ℕ) : Polynomial (field (k - 1)) :=
  match k with
  | 0 => 0
  | k + 1 => X^2 + (C (list k).getLastI) * X + 1

@[coe]
theorem field_eq_adjoinRoot_poly (k : ℕ) (k_pos : k > 0) : AdjoinRoot (poly k) = field k := by
  induction k with
  | zero => absurd k_pos ; simp
  | succ k _ => simp [AbstractBinaryTower]

instance coe_field_adjoinRoot (k : ℕ) (k_pos : k > 0) : Coe (AdjoinRoot (poly k)) (field k) where
  coe := Eq.mp (field_eq_adjoinRoot_poly k k_pos)


-- We call the special extension field elements Z_k
@[simp]
def Z (k : ℕ) : field k := (list k).getLastI

-- @[simp]
-- theorem Z_eq_adjointRoot_root (k : ℕ) (k_pos : k > 0) [Eq (AdjoinRoot (poly k)) (field k)] : Z k = AdjoinRoot.root (poly k) := by
--   simp [Z, field_eq_adjoinRoot_poly k k_pos]


@[simp]
theorem list_length (k : ℕ) : List.length (AbstractBinaryTower k).2.1 = k + 1 := by
  induction k with
  | zero => simp [AbstractBinaryTower]
  | succ k IH =>
    conv in Prod.fst _ => simp [AbstractBinaryTower]
    simp [List.length_append _ _, IH]

@[simp]
theorem list_nonempty (k : ℕ) : (AbstractBinaryTower k).2.1 ≠ [] := List.ne_nil_of_length_eq_succ (list_length k)


instance polyIrreducible (n : ℕ) : Irreducible (poly n) := sorry


instance polyIrreducibleFact (n : ℕ) : Fact (Irreducible (poly n)) := ⟨polyIrreducible n⟩


instance isFieldBTF (n : ℕ) : Field (AbstractBinaryTower n).1 := by
  induction n with
  | zero => simp [AbstractBinaryTower] ; exact inferInstance
  | succ n =>
    simp [AbstractBinaryTower]
    apply AdjoinRoot.field (polyIrreducibleFact (n + 1))




-- Possible direction: define alternate definition of BTF as Quotient of MvPolynomial (Fin n) GF(2) by the ideal generated by special field elements
-- What would this definition give us?

end AbstractBinaryTower

end

/- Concrete implementation of BTF uses BitVec -/

def ConcreteBinaryTower (k : ℕ) :=
  match k with
  | 0 => BitVec 1
  | k + 1 => BitVec (2 ^ (2 ^ (k - 1)))


-- Define all arithmetic operations



-- Define a field isomorphism
