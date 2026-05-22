/-
  LogarithmicStorage: Formal Verification in Lean 4

  Proving correctness and bounds for logarithmic value compression
  used in MegaDog and generalizable to any exponential-growth domain.

  SPDX-License-Identifier: MPL-2.0
-/

import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Data.Real.Basic

namespace LogarithmicStorage

/-- Precision factor for fixed-point representation -/
noncomputable def PRECISION : ℝ := 1000000

/-- LogValue represents a value stored as ln(x) * PRECISION -/
structure LogValue where
  raw : ℤ
  deriving Repr, DecidableEq

/-- Convert actual value to log representation -/
noncomputable def toLog (x : ℝ) (_h : x > 0) : LogValue :=
  ⟨Int.floor (Real.log x * PRECISION)⟩

/-- Convert log representation back to actual value -/
noncomputable def fromLog (lv : LogValue) : ℝ :=
  Real.exp (lv.raw / PRECISION)

/-- Addition in log space is multiplication: ln(a) + ln(b) = ln(a * b) -/
theorem log_add_is_multiply (a b : ℝ) (ha : a > 0) (hb : b > 0) :
    Real.log a + Real.log b = Real.log (a * b) := by
  rw [Real.log_mul (ne_of_gt ha) (ne_of_gt hb)]

/-- Multiply two values (add in log space) - EXACT -/
def mul (a b : LogValue) : LogValue :=
  ⟨a.raw + b.raw⟩

/-- Divide two values (subtract in log space) - EXACT -/
def div (a b : LogValue) : LogValue :=
  ⟨a.raw - b.raw⟩

/-- Power operation (multiply in log space) - EXACT -/
def pow (base : LogValue) (e : ℤ) : LogValue :=
  ⟨base.raw * e⟩

/-- Root operation (divide in log space) - EXACT -/
def root (base : LogValue) (n : ℕ) (_hn : n > 0) : LogValue :=
  ⟨base.raw / n⟩

/-- Add two values (requires approximation).
    ln(a + b) ≈ max(ln(a), ln(b)) + ln(2) when a ≈ b
    ln(a + b) ≈ max(ln(a), ln(b)) when one dominates -/
def add (a b : LogValue) : LogValue :=
  let diff := (a.raw - b.raw).natAbs
  if diff > 10 * 1000000 then
    ⟨max a.raw b.raw⟩
  else
    ⟨max a.raw b.raw + 693147⟩

/-- Multiplication in log space is exact via exp_add -/
theorem mul_exact (a b : LogValue) :
    fromLog (mul a b) = fromLog a * fromLog b := by
  simp only [mul, fromLog]
  rw [← Real.exp_add]
  congr 1
  push_cast
  ring

/-!
## Helper lemmas for roundtrip error bound

The roundtrip proof relies on two key bounds:
1. `fromLog (toLog x) ≤ x` (floor rounds down)
2. `x * exp(-1/P) ≤ fromLog (toLog x)` (floor rounds down by at most 1)

Combined with `1 - exp(-t) ≤ t` (from `Real.one_sub_le_exp_neg`), these give
a relative error bound of `1/PRECISION`.
-/

/-- Upper bound: converting to LogValue and back never exceeds the original.
    Follows from `⌊y⌋ ≤ y` and monotonicity of exp. -/
private lemma fromLog_toLog_le (x : ℝ) (hx : x > 0) :
    fromLog (toLog x hx) ≤ x := by
  simp only [fromLog, toLog]
  have hP : (0 : ℝ) < PRECISION := by norm_num [PRECISION]
  have h1 : (⌊Real.log x * PRECISION⌋ : ℝ) ≤ Real.log x * PRECISION :=
    Int.floor_le _
  have h2 : (↑⌊Real.log x * PRECISION⌋ : ℝ) / PRECISION ≤ Real.log x := by
    rw [div_le_iff₀ hP]
    linarith [mul_comm (Real.log x) PRECISION]
  calc Real.exp (↑⌊Real.log x * PRECISION⌋ / PRECISION)
      ≤ Real.exp (Real.log x) := Real.exp_le_exp.mpr h2
    _ = x := Real.exp_log hx

/-- Lower bound: the roundtrip value is at least `x * exp(-1/P)`.
    Follows from `⌊y⌋ > y - 1` (i.e. `Int.sub_one_lt_floor`). -/
private lemma fromLog_toLog_lower (x : ℝ) (hx : x > 0) :
    x * Real.exp (-(1 / PRECISION)) ≤ fromLog (toLog x hx) := by
  simp only [fromLog, toLog]
  have hP : (0 : ℝ) < PRECISION := by norm_num [PRECISION]
  rw [← Real.exp_log hx, ← Real.exp_add, Real.exp_le_exp]
  simp only [Real.log_exp]
  have hsub : Real.log x * PRECISION - 1 < ⌊Real.log x * PRECISION⌋ :=
    Int.sub_one_lt_floor _
  have key : (Real.log x * PRECISION - 1) / PRECISION = Real.log x - 1 / PRECISION := by
    field_simp
  linarith [div_lt_div_of_pos_right hsub hP]

/-- Roundtrip error is bounded by 1/PRECISION.
    For any positive real x, converting to LogValue and back introduces
    at most 1/PRECISION relative error.

    Proof sketch:
    - Let y = log(x) * P. Then fromLog(toLog(x)) = exp(⌊y⌋/P).
    - Since ⌊y⌋ ≤ y, we get exp(⌊y⌋/P) ≤ exp(y/P) = x  (upper bound).
    - Since ⌊y⌋ > y - 1, we get exp(⌊y⌋/P) > exp((y-1)/P) = x·exp(-1/P)  (lower bound).
    - Therefore 0 ≤ x - exp(⌊y⌋/P) ≤ x·(1 - exp(-1/P)).
    - By Real.one_sub_le_exp_neg: 1 - 1/P ≤ exp(-1/P), so 1 - exp(-1/P) ≤ 1/P.
    - Hence |exp(⌊y⌋/P) - x| / x ≤ 1/P. -/
theorem roundtrip_error_bounded (x : ℝ) (hx : x > 0) :
    |fromLog (toLog x hx) - x| / x ≤ 1 / PRECISION := by
  have hP : (0 : ℝ) < PRECISION := by norm_num [PRECISION]
  have h_le : fromLog (toLog x hx) ≤ x := fromLog_toLog_le x hx
  have h_sub_nonpos : fromLog (toLog x hx) - x ≤ 0 := by linarith
  rw [abs_of_nonpos h_sub_nonpos, neg_sub]
  -- Goal: (x - fromLog(toLog x)) / x ≤ 1/P
  have h_lower : x * Real.exp (-(1 / PRECISION)) ≤ fromLog (toLog x hx) :=
    fromLog_toLog_lower x hx
  -- From lower bound: x - fromLog ≤ x - x*exp(-1/P) = x*(1 - exp(-1/P))
  have h1 : x - fromLog (toLog x hx) ≤ x * (1 - Real.exp (-(1 / PRECISION))) := by
    linarith
  -- From Real.one_sub_le_exp_neg: 1 - (1/P) ≤ exp(-1/P), so 1 - exp(-1/P) ≤ 1/P
  have h_exp_bound : 1 - (1 / PRECISION) ≤ Real.exp (-(1 / PRECISION)) :=
    Real.one_sub_le_exp_neg _
  have h2 : 1 - Real.exp (-(1 / PRECISION)) ≤ 1 / PRECISION := by linarith
  -- Therefore x*(1 - exp(-1/P)) ≤ x*(1/P)
  have h3 : x * (1 - Real.exp (-(1 / PRECISION))) ≤ x * (1 / PRECISION) :=
    mul_le_mul_of_nonneg_left h2 (le_of_lt hx)
  -- And (x - fromLog) ≤ x*(1/P), so (x - fromLog)/x ≤ (x*(1/P))/x = 1/P
  have h4 : x - fromLog (toLog x hx) ≤ x * (1 / PRECISION) := by linarith
  calc (x - fromLog (toLog x hx)) / x
      ≤ (x * (1 / PRECISION)) / x :=
        div_le_div_of_nonneg_right h4 (le_of_lt hx)
    _ = 1 / PRECISION := by
        rw [mul_div_cancel_left₀ _ (ne_of_gt hx)]

/-!
## Storage savings proof

We show that for n > exp(18), logarithmic storage uses fewer bits than
direct storage. The proof chain:
1. exp(1) ≥ 8/3 (from 4-term Taylor series)
2. exp(18) = exp(1)^18 ≥ (8/3)^18 > 18 × 10^6  (norm_num arithmetic)
3. For t ≥ 18: exp(t) ≥ exp(18)·exp(t-18) ≥ exp(18)·(1+(t-18)) > t × 10^6
4. Therefore n > log(n) × P, so log(log(n)×P) < log(n).
-/

/-- exp(1) ≥ 8/3, from the first 4 terms of the Taylor series for exp. -/
private lemma exp_one_ge : Real.exp 1 ≥ 8 / 3 := by
  have h := Real.sum_le_exp_of_nonneg (show (0:ℝ) ≤ 1 by norm_num) 4
  simp [Finset.sum_range_succ, Nat.factorial] at h; linarith

/-- exp(18) = exp(1)^18 by the homomorphism property of exp. -/
private lemma exp_18_eq : Real.exp 18 = (Real.exp 1) ^ 18 := by
  have h := Real.exp_nat_mul 1 18; simp at h; linarith

/-- exp(18) > 18 × 10^6, combining the Taylor lower bound with norm_num arithmetic.
    Key step: (8/3)^18 = 8^18/3^18 > 18 × 10^6. -/
private lemma exp_18_gt : Real.exp 18 > 18 * PRECISION := by
  rw [exp_18_eq]
  have h3 : (8 / 3 : ℝ) ^ 18 ≤ (Real.exp 1) ^ 18 :=
    pow_le_pow_left₀ (by norm_num) exp_one_ge 18
  simp only [PRECISION]
  linarith [show (8 : ℝ)^18 / 3^18 > 18 * 1000000 from by norm_num,
            show ((8:ℝ)/3)^18 = 8^18 / 3^18 from by ring]

/-- For t ≥ 18, exp(t) > t × PRECISION.
    Write t = 18 + s where s ≥ 0. Then:
    exp(t) = exp(18)·exp(s) ≥ exp(18)·(1+s) = exp(18) + exp(18)·s
           > 18·P + P·s = (18+s)·P = t·P. -/
private lemma exp_gt_mul_precision (t : ℝ) (ht : t ≥ 18) :
    Real.exp t > t * PRECISION := by
  have hs : t - 18 ≥ 0 := by linarith
  have h_exp_s : Real.exp (t - 18) ≥ 1 + (t - 18) := by
    linarith [Real.add_one_le_exp (t - 18)]
  have h18 := exp_18_gt
  have h18_ge_P : Real.exp 18 > PRECISION := by
    simp only [PRECISION] at h18 ⊢; linarith
  have hexp : Real.exp t = Real.exp 18 * Real.exp (t - 18) := by
    rw [← Real.exp_add]; ring_nf
  rw [hexp]
  have h1 : Real.exp 18 * Real.exp (t - 18) ≥ Real.exp 18 * (1 + (t - 18)) :=
    mul_le_mul_of_nonneg_left h_exp_s (le_of_lt (Real.exp_pos 18))
  have h3 : Real.exp 18 + Real.exp 18 * (t - 18) > 18 * PRECISION + PRECISION * (t - 18) := by
    have : Real.exp 18 * (t - 18) ≥ PRECISION * (t - 18) :=
      mul_le_mul_of_nonneg_right (le_of_lt h18_ge_P) hs
    linarith
  linarith [show 18 * PRECISION + PRECISION * (t - 18) = t * PRECISION from by ring,
            show Real.exp 18 * (1 + (t - 18)) = Real.exp 18 + Real.exp 18 * (t - 18) from by ring]

/-- Storage savings at scale: for large n, logarithmic storage uses
    asymptotically fewer bits than direct storage.
    log₂(ln(n) * P) < log₂(n) for n > e^18. -/
noncomputable def STORAGE_SAVINGS_THRESHOLD : ℝ := Real.exp 18

theorem storage_savings (n : ℕ) (_hn : n > 1)
    (hn_large : (n : ℝ) > STORAGE_SAVINGS_THRESHOLD) :
    ∃ (savings : ℝ), savings > 0 ∧
    Real.log (Real.log n * PRECISION) < Real.log n - savings := by
  have hP : PRECISION > (0 : ℝ) := by norm_num [PRECISION]
  have hn_pos : (n : ℝ) > 0 := lt_trans (Real.exp_pos 18) hn_large
  -- log(n) > 18 since n > exp(18)
  have h_log_n : Real.log n > 18 := by
    have : Real.log (Real.exp 18) < Real.log n :=
      Real.log_lt_log (Real.exp_pos 18) hn_large
    rwa [Real.log_exp] at this
  have h_log_pos : Real.log n > 0 := by linarith
  have h_prod_pos : Real.log n * PRECISION > 0 := mul_pos h_log_pos hP
  -- n > log(n) * P (from exp_gt_mul_precision applied to t = log(n))
  have h_n_gt : (n : ℝ) > Real.log n * PRECISION := by
    have h1 := exp_gt_mul_precision (Real.log n) (le_of_lt h_log_n)
    rwa [Real.exp_log hn_pos] at h1
  -- log(log(n)*P) < log(n) since log(n)*P < n and log is monotone
  have h_key : Real.log (Real.log n * PRECISION) < Real.log n :=
    Real.log_lt_log h_prod_pos h_n_gt
  -- Witness: savings = (log(n) - log(log(n)*P)) / 2 > 0
  exact ⟨(Real.log n - Real.log (Real.log n * PRECISION)) / 2, by linarith, by linarith⟩

/-!
## Addition approximation error bound

The `add` function approximates `ln(a + b)` using either:
- `max(ln(a), ln(b))` when one value dominates (diff > 10P), or
- `max(ln(a), ln(b)) + 693147` when values are similar (693147 ≈ ln(2)×P).

We prove the result is always within a factor of 2 of the true sum.

Key facts:
- exp(max(a,b)/P) ≤ exp(a/P) + exp(b/P)  (max ≤ sum, since exp > 0)
- exp(max(a,b)/P) ≥ (exp(a/P) + exp(b/P))/2  (max ≥ average)
- exp(693147/10^6) ≤ 2  (from 8-term Taylor approximation of exp)
- exp(693147/10^6) ≥ 1  (exp is always ≥ 1 for nonneg argument)
-/

/-- exp(693147/10^6) ≤ 2, verified via 8-term Taylor series and `Real.exp_bound`.
    Since 693147/10^6 ≈ ln(2) and ln(2) < 693148/10^6, we have
    exp(693147/10^6) < exp(ln(2)) = 2. -/
private lemma exp_ln2_le_two : Real.exp (693147 / 1000000 : ℝ) ≤ 2 := by
  have hx : |(693147 / 1000000 : ℝ)| ≤ 1 := by
    rw [abs_of_nonneg (by norm_num : (0:ℝ) ≤ 693147 / 1000000)]; norm_num
  have hx' : |(693147 / 1000000 : ℝ)| = 693147 / 1000000 :=
    abs_of_nonneg (by norm_num)
  have h := Real.exp_bound hx (show 0 < 8 by norm_num)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.factorial,
    Nat.succ_eq_add_one, pow_zero, pow_one, pow_succ] at h
  rw [hx'] at h; norm_num at h
  linarith [(abs_le.mp h).2]

/-- exp(max(a,b)/P) ≤ exp(a/P) + exp(b/P), since the max equals one of the
    terms and the other term is positive. -/
private lemma exp_max_le_sum (a b : ℤ) :
    Real.exp ((↑(max a b) : ℝ) / PRECISION) ≤
    Real.exp ((a : ℝ) / PRECISION) + Real.exp ((b : ℝ) / PRECISION) := by
  rcases le_total a b with hab | hab
  · simp [max_eq_right hab]
    linarith [Real.exp_pos ((a : ℝ) / PRECISION)]
  · simp [max_eq_left hab]
    linarith [Real.exp_pos ((b : ℝ) / PRECISION)]

/-- exp(max(a,b)/P) ≥ (exp(a/P) + exp(b/P))/2, since the max is at least
    as large as each term, hence at least the average. -/
private lemma exp_max_ge_half_sum (a b : ℤ) :
    Real.exp ((↑(max a b) : ℝ) / PRECISION) ≥
    (Real.exp ((a : ℝ) / PRECISION) + Real.exp ((b : ℝ) / PRECISION)) / 2 := by
  rcases le_total a b with hab | hab
  · simp [max_eq_right hab]
    have h1 : Real.exp ((a : ℝ) / PRECISION) ≤ Real.exp ((b : ℝ) / PRECISION) := by
      rw [Real.exp_le_exp]
      exact div_le_div_of_nonneg_right (Int.cast_le.mpr hab) (by norm_num [PRECISION])
    linarith
  · simp [max_eq_left hab]
    have h1 : Real.exp ((b : ℝ) / PRECISION) ≤ Real.exp ((a : ℝ) / PRECISION) := by
      rw [Real.exp_le_exp]
      exact div_le_div_of_nonneg_right (Int.cast_le.mpr hab) (by norm_num [PRECISION])
    linarith

/-- Add approximation error is bounded by factor of 2.
    computed ≤ 2 * actual ∧ computed ≥ actual / 2.

    Case 1 (one dominates, diff > 10P): result = max(a,b).
      Upper: exp(max/P) ≤ sum (trivially).
      Lower: exp(max/P) ≥ sum/2 (max ≥ average).

    Case 2 (similar magnitudes): result = max(a,b) + 693147.
      Upper: exp((max+693147)/P) = exp(max/P)·exp(693147/P) ≤ sum·2  (using exp(693147/P) ≤ 2).
      Lower: exp((max+693147)/P) ≥ exp(max/P)·1 ≥ sum/2  (using exp(693147/P) ≥ 1). -/
theorem add_error_bounded (a b : LogValue) :
    let result := add a b
    let actual := fromLog a + fromLog b
    let computed := fromLog result
    computed ≤ 2 * actual ∧ computed ≥ actual / 2 := by
  simp only [add]
  split
  case isTrue h =>
    -- Case 1: diff > 10*P, result = ⟨max a.raw b.raw⟩
    constructor
    · -- exp(max/P) ≤ 2 * (exp(a/P) + exp(b/P))
      simp only [fromLog]
      linarith [exp_max_le_sum a.raw b.raw,
                Real.exp_pos ((a.raw : ℝ) / PRECISION),
                Real.exp_pos ((b.raw : ℝ) / PRECISION)]
    · -- exp(max/P) ≥ (exp(a/P) + exp(b/P)) / 2
      simp only [fromLog]
      exact exp_max_ge_half_sum a.raw b.raw
  case isFalse h =>
    -- Case 2: diff ≤ 10*P, result = ⟨max a.raw b.raw + 693147⟩
    have hP_eq : (693147 : ℝ) / PRECISION = 693147 / 1000000 := by simp [PRECISION]
    have h_split : (↑(max a.raw b.raw + 693147) : ℝ) / PRECISION =
           (↑(max a.raw b.raw) : ℝ) / PRECISION + 693147 / PRECISION := by push_cast; ring
    constructor
    · -- exp((max+693147)/P) ≤ 2 * (exp(a/P) + exp(b/P))
      simp only [fromLog]
      rw [h_split, Real.exp_add]
      have h1 := exp_max_le_sum a.raw b.raw
      have h2 : Real.exp (693147 / PRECISION) ≤ 2 := by rw [hP_eq]; exact exp_ln2_le_two
      nlinarith [Real.exp_pos ((↑(max a.raw b.raw) : ℝ) / PRECISION)]
    · -- exp((max+693147)/P) ≥ (exp(a/P) + exp(b/P)) / 2
      simp only [fromLog]
      rw [h_split, Real.exp_add]
      have h1 := exp_max_ge_half_sum a.raw b.raw
      have h3 : Real.exp (693147 / PRECISION) ≥ 1 := by
        rw [hP_eq]; linarith [Real.add_one_le_exp (693147 / (1000000 : ℝ))]
      nlinarith [Real.exp_pos ((↑(max a.raw b.raw) : ℝ) / PRECISION)]

/-- Gas cost savings ratio for batched operations -/
def gas_savings_ratio : ℕ := 500000 / 8000

end LogarithmicStorage
