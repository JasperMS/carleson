import Carleson.Classical.HilbertKernel
import Carleson.Classical.DirichletKernel
import Carleson.Classical.SpectralProjectionBound
import Carleson.ToMathlib.MeasureTheory.Integral.MeanInequalities

/- This file contains the proof that the Hilbert kernel is a bounded operator. -/

noncomputable section

open scoped Real ENNReal
open Complex ComplexConjugate MeasureTheory Bornology Set
-- open MeasureTheory Function Metric Bornology Real ENNReal MeasureTheory.ENNReal MeasureTheory



section
@[reducible]
def doublingMeasure_real_two : DoublingMeasure ℝ 2 :=
  InnerProductSpace.DoublingMeasure.mono (by simp)

instance doublingMeasure_real_16 : DoublingMeasure ℝ (2 ^ 4 : ℕ) :=
  doublingMeasure_real_two.mono (by norm_num)
end

/-- The modulation operator `M_n g`, defined in (11.3.1) -/
def modulationOperator (n : ℤ) (g : ℝ → ℂ) (x : ℝ) : ℂ :=
  g x * Complex.exp (.I * n * x)

/-- The approximate Hilbert transform `L_N g`, defined in (11.3.2).
defined slightly differently. -/
def approxHilbertTransform (n : ℕ) (g : ℝ → ℂ) (x : ℝ) : ℂ :=
  (n : ℂ)⁻¹ * ∑ k ∈ .Ico n (2 * n),
    modulationOperator (-k) (partialFourierSum k (modulationOperator k g)) x

/-- The kernel `k_r(x)` defined in (11.3.11).
When used, we may assume that `r ∈ Ioo 0 1`.
Todo: find better name? -/
def niceKernel (r : ℝ) (x : ℝ) : ℝ :=
  if Complex.exp (.I * x) = 1 then r⁻¹ else
    min r⁻¹ (1 + r / normSq (1 - Complex.exp (.I * x)))

-- todo: write lemmas for `niceKernel` (periodicity, evenness)

/-- Lemma 11.1.8 -/
lemma mean_zero_oscillation {n : ℤ} (hn : n ≠ 0) :
    ∫ x in (0)..2 * π, Complex.exp (.I * n * x) = 0 := by
  rw [integral_exp_mul_complex (by simp [hn])]
  simp [sub_eq_zero, Complex.exp_eq_one_iff, hn, ← mul_assoc, mul_comm Complex.I,
    mul_right_comm _ Complex.I]


/-- Lemma 11.5.1
Note: might not be used if we can use `spectral_projection_bound_lp` below.
-/
lemma partial_sum_projection {f : ℝ → ℂ} {n : ℕ}
    (hf : MemLp f ∞ volume) (periodic_f : f.Periodic (2 * π)) {x : ℝ} :
    partialFourierSum n (partialFourierSum n f) x = partialFourierSum n f x := by
  sorry

/-- Lemma 11.5.2.
Note: might not be used if we can use `spectral_projection_bound_lp` below.
-/
lemma partial_sum_selfadjoint {f g : ℝ → ℂ} {n : ℕ}
    (hf : MemLp f ∞ volume) (periodic_f : f.Periodic (2 * π))
    (hg : MemLp g ∞ volume) (periodic_g : g.Periodic (2 * π)) :
    ∫ x in (0)..2 * π, conj (partialFourierSum n f x) * g x =
    ∫ x in (0)..2 * π, conj (f x) * partialFourierSum n g x := by
  sorry


--lemma eLpNorm_eq_norm {f : ℝ → ℂ} {p : ENNReal} (hf : MemLp f p) :
--    ‖MemLp.toLp f hf‖ = eLpNorm f p := by
--  sorry

theorem AddCircle.haarAddCircle_eq_smul_volume {T : ℝ} [hT : Fact (0 < T)] :
    (@haarAddCircle T _) = (ENNReal.ofReal T)⁻¹ • (volume : Measure (AddCircle T)) := by
  rw [volume_eq_smul_haarAddCircle, ← smul_assoc, smul_eq_mul,
    ENNReal.inv_mul_cancel (by simp [hT.out]) ENNReal.ofReal_ne_top, one_smul]

open AddCircle in
/-- Lemma 11.1.10.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
-- todo: add lemma that relates `eLpNorm ((Ioc a b).indicator f)` to `∫ x in a..b, _`
lemma spectral_projection_bound {f : ℝ → ℂ} {n : ℕ} (hmf : Measurable f) :
    eLpNorm ((Ioc 0 (2 * π)).indicator (partialFourierSum n f)) 2 ≤
    eLpNorm ((Ioc 0 (2 * π)).indicator f) 2 := by
  -- Proof by massaging the statement of `spectral_projection_bound_lp` into this.
  by_cases hf_L2 : eLpNorm ((Ioc 0 (2 * π)).indicator f) 2 = ⊤
  · rw [hf_L2]
    exact OrderTop.le_top _
  push_neg at hf_L2
  rw [← lt_top_iff_ne_top] at hf_L2
  have : Fact (0 < 2 * π) := ⟨by positivity⟩
  have lift_MemLp : MemLp (liftIoc (2 * π) 0 f) 2 haarAddCircle := by
    unfold MemLp
    constructor
    · rw [haarAddCircle_eq_smul_volume]
      apply AEStronglyMeasurable.smul_measure
      exact hmf.aestronglyMeasurable.liftIoc (2 * π) 0
    · rw [haarAddCircle_eq_smul_volume, eLpNorm_smul_measure_of_ne_top (by trivial),
        eLpNorm_liftIoc _ _ hmf.aestronglyMeasurable, smul_eq_mul, zero_add]
      apply ENNReal.mul_lt_top _ hf_L2
      rw [← ENNReal.ofReal_inv_of_pos this.out]
      apply ENNReal.rpow_lt_top_of_nonneg ENNReal.toReal_nonneg ENNReal.ofReal_ne_top
  let F : Lp ℂ 2 haarAddCircle :=
    MemLp.toLp (AddCircle.liftIoc (2 * π) 0 f) lift_MemLp

  have lp_version := spectral_projection_bound_lp (N := n) F
  rw [Lp.norm_def, Lp.norm_def,
    ENNReal.toReal_le_toReal (Lp.eLpNorm_ne_top (partialFourierSumLp 2 n F)) (Lp.eLpNorm_ne_top F)]
    at lp_version

  rw [← zero_add (2 * π), ← eLpNorm_liftIoc _ _ hmf.aestronglyMeasurable,
    ← eLpNorm_liftIoc _ _ partialFourierSum_uniformContinuous.continuous.aestronglyMeasurable,
    volume_eq_smul_haarAddCircle,
    eLpNorm_smul_measure_of_ne_top (by trivial), eLpNorm_smul_measure_of_ne_top (by trivial),
    smul_eq_mul, smul_eq_mul, ENNReal.mul_le_mul_left (by simp [Real.pi_pos]) (by simp)]
  have ae_eq_right : F =ᶠ[ae haarAddCircle] liftIoc (2 * π) 0 f := MemLp.coeFn_toLp _
  have ae_eq_left : partialFourierSumLp 2 n F =ᶠ[ae haarAddCircle]
      liftIoc (2 * π) 0 (partialFourierSum n f) :=
    Filter.EventuallyEq.symm (partialFourierSum_aeeq_partialFourierSumLp 2 n f lift_MemLp)
  rw [← eLpNorm_congr_ae ae_eq_right, ← eLpNorm_congr_ae ae_eq_left]
  exact lp_version


/-- Lemma 11.3.1.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
lemma modulated_averaged_projection {g : ℝ → ℂ} {n : ℕ}
    (hmg : Measurable g) (hg : MemLp g ∞ volume) (periodic_g : g.Periodic (2 * π)) :
    eLpNorm ((Ioc 0 (2 * π)).indicator (approxHilbertTransform n g)) ≤
    eLpNorm ((Ioc 0 (2 * π)).indicator g) := by
  sorry

/- Lemma 11.3.2 `periodic-domain-shift` is in Mathlib. -/

/-- Lemma 11.3.3.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
lemma young_convolution {f g : ℝ → ℂ} (hmf : AEMeasurable f) (periodic_f : f.Periodic (2 * π))
    (hmg : AEMeasurable g) (periodic_g : g.Periodic (2 * π)) :
    eLpNorm ((Ioc 0 (2 * π)).indicator fun x ↦ ∫ y in (0)..2 * π, f y * g (x - y)) 2 ≤
    eLpNorm ((Ioc 0 (2 * π)).indicator f) 2 * eLpNorm ((Ioc 0 (2 * π)).indicator g) 1  := by
  have : Fact (0 < 2 * π) := ⟨mul_pos two_pos Real.pi_pos⟩
  have h2 : (1 : ℝ≥0∞) ≤ 2 := by exact one_le_two
  simpa [zero_add] using ENNReal.eLpNorm_Ioc_convolution_le_of_norm_le_mul
    (ContinuousLinearMap.mul ℝ ℂ) 0 h2 (le_refl 1) h2 (by rw [inv_one])
    periodic_f periodic_g hmf.aestronglyMeasurable hmg.aestronglyMeasurable 1 (by simp)

/-- Lemma 11.3.4.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
lemma integrable_bump_convolution {f g : ℝ → ℂ} {n : ℕ}
    (hf : MemLp f ∞ volume) (periodic_f : f.Periodic (2 * π))
    (hg : MemLp g ∞ volume) (periodic_g : g.Periodic (2 * π))
    {r : ℝ} (hr : r ∈ Ioo 0 π) (hg : ∀ x, ‖g x‖ ≤ niceKernel r x) :
    eLpNorm ((Ioc 0 (2 * π)).indicator fun x ↦ ∫ y in (0)..2 * π, f y * g (x - y)) 2 ≤
    2 ^ (5 : ℝ) * eLpNorm ((Ioc 0 (2 * π)).indicator f) 2 := by
  sorry

/-- The function `L'`, defined in the Proof of Lemma 11.3.5. -/
def dirichletApprox (n : ℕ) (x : ℝ) : ℂ :=
  (n : ℂ)⁻¹ * ∑ k ∈ .Ico n (2 * n), dirichletKernel k x * Complex.exp (- Complex.I * k * x)

/-- Lemma 11.3.5, part 1. -/
lemma continuous_dirichletApprox {n : ℕ} : Continuous (dirichletApprox n) := by
  sorry

/-- Lemma 11.3.5, part 2. -/
lemma periodic_dirichletApprox (n : ℕ) : (dirichletApprox n).Periodic (2 * π) := by
  sorry

/-- Lemma 11.3.5, part 3.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
lemma approxHilbertTransform_eq_dirichletApprox {f : ℝ → ℂ} {n : ℕ}
    (hf : MemLp f ∞ volume) (periodic_f : f.Periodic (2 * π))
    {n : ℕ} {x : ℝ} :
    approxHilbertTransform n f x =
    (2 * π)⁻¹ * ∫ y in (0)..2 * π, f y * dirichletApprox n (x - y) := by
  sorry

/-- Lemma 11.3.5, part 4.
The blueprint states this on `[-π, π]`, but I think we can consistently change this to `(0, 2π]`.
-/
lemma dist_dirichletApprox_le {f : ℝ → ℂ} {n : ℕ}
    (hf : MemLp f ∞ volume) (periodic_f : f.Periodic (2 * π))
    {r : ℝ} (hr : r ∈ Ioo 0 1) {n : ℕ} (hn : n = ⌈r⁻¹⌉₊) {x : ℝ} :
    dist (dirichletApprox n x) ({y : ℂ | ‖y‖ ∈ Ioo r 1}.indicator 1 x) ≤
    2 ^ (5 : ℝ) * niceKernel r x := by
  sorry

/- Lemma 11.1.6.
This verifies the assumption on the operators T_r in two-sided metric space Carleson.
Its proof is done in Section 11.3 (The truncated Hilbert transform) and is yet to be formalized.

Note: we might be able to simplify the proof in the blueprint by using real interpolation
`MeasureTheory.exists_hasStrongType_real_interpolation`.
Note: In the blueprint we have the condition `r < 1`.
Can we get rid of that condition or otherwise fix `two_sided_metric_carleson`?
-/
lemma Hilbert_strong_2_2 ⦃r : ℝ⦄ (hr : 0 < r) :
    HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts 4) :=
  sorry
