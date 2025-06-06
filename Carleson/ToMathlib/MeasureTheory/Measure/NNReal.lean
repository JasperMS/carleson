import Mathlib.MeasureTheory.Measure.Haar.OfBasis
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open MeasureTheory NNReal ENNReal Set

noncomputable
instance NNReal.MeasureSpace : MeasureSpace ℝ≥0 := ⟨Measure.Subtype.measureSpace.volume⟩

lemma NNReal.volume_val {s : Set ℝ≥0} : volume s = volume (Subtype.val '' s) := by
  apply comap_subtype_coe_apply measurableSet_Ici

-- sanity check: this measure is what you expect
example : volume (Ioo (3 : ℝ≥0) 5) = 2 := by
  have : Subtype.val '' Ioo (3 : ℝ≥0) 5 = Ioo (3 : ℝ) 5 := by
    ext x
    constructor
    · simp only [val_eq_coe, mem_image, mem_Ioo, Subtype.exists, coe_mk, exists_and_right,
      exists_eq_right, forall_exists_index, and_imp]
      intro hx1 hx2 hx3
      exact ⟨hx2, hx3⟩
    · intro hx
      simp only [val_eq_coe, mem_image, mem_Ioo, Subtype.exists, coe_mk, exists_and_right,
        exists_eq_right]
      have : 0 ≤ x := by linarith [hx.1]
      use this
      rw [← Subtype.coe_lt_coe, ← Subtype.coe_lt_coe]
      exact hx

  rw [NNReal.volume_val, this]
  simpa only [Real.volume_Ioo, ENNReal.ofReal_eq_ofNat] using by norm_num

-- integral over a function over NNReal equals the integral over the right set of real numbers

noncomputable
instance : MeasureSpace ℝ≥0∞ where
  volume := (volume : Measure ℝ≥0).map ENNReal.ofNNReal

--TODO: move these lemmas somewhere else?
lemma ENNReal.map_toReal_eq_map_toReal_comap_ofReal {s : Set ℝ≥0∞} (h : ∞ ∉ s) :
    ENNReal.toReal '' s = NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) := by
  ext x
  simp only [mem_image, mem_preimage]
  constructor
  · rintro ⟨y, hys, hyx⟩
    have : y ≠ ∞ := ne_of_mem_of_not_mem hys h
    use y.toNNReal
    rw [coe_toNNReal this]
    use hys
    rwa [coe_toNNReal_eq_toReal]
  · rintro ⟨y, hys, hyx⟩
    use ENNReal.ofNNReal y, hys, hyx

lemma ENNReal.map_toReal_eq_map_toReal_comap_ofReal' {s : Set ℝ≥0∞} (h : ∞ ∈ s) :
    ENNReal.toReal '' s = NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) ∪ {0}:= by
  ext x
  simp only [mem_image, mem_preimage]
  constructor
  · rintro ⟨y, hys, hyx⟩
    by_cases hy : y = ∞
    · rw [← hyx, hy]
      simp
    left
    use y.toNNReal
    simp only [mem_preimage]
    rw [coe_toNNReal hy]
    use hys
    rwa [coe_toNNReal_eq_toReal]
  · rintro (⟨y, hys, hyx⟩ | hx)
    · use ENNReal.ofNNReal y, hys, hyx
    · use ∞, h
      simp only [toReal_top, hx.symm]

lemma ENNReal.map_toReal_ae_eq_map_toReal_comap_ofReal {s : Set ℝ≥0∞} :
    ENNReal.toReal '' s =ᵐ[volume] NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) := by
  by_cases h : ∞ ∈ s
  · rw [ENNReal.map_toReal_eq_map_toReal_comap_ofReal' h, union_singleton]
    apply insert_ae_eq_self
  rw [ENNReal.map_toReal_eq_map_toReal_comap_ofReal h]


lemma ENNReal.volume_val {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    volume s = volume (ENNReal.toReal '' s) := by
  calc volume s
    _ = volume (ENNReal.ofNNReal ⁻¹' s) :=
      MeasureTheory.Measure.map_apply_of_aemeasurable (by fun_prop) hs
    _ = volume (NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s)) := NNReal.volume_val
    _ = volume (ENNReal.toReal '' s) := Eq.symm (measure_congr ENNReal.map_toReal_ae_eq_map_toReal_comap_ofReal)

--TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Icc_eq_Icc {a b : ℝ≥0∞} (ha : a ≠ ∞) (hb : b ≠ ∞) :
    ENNReal.toReal '' Set.Icc a b = Set.Icc a.toReal b.toReal := by
  ext x
  simp only [mem_image, mem_Icc]
  constructor
  · rintro ⟨y, hy, hyx⟩
    rwa [← hyx,
          toReal_le_toReal ha (lt_top_iff_ne_top.mp (hy.2.trans_lt (lt_top_iff_ne_top.mpr hb))),
          toReal_le_toReal (lt_top_iff_ne_top.mp (hy.2.trans_lt (lt_top_iff_ne_top.mpr hb))) hb ]
  · rintro hx
    use ENNReal.ofReal x
    constructor
    · rwa [le_ofReal_iff_toReal_le ha (le_trans toReal_nonneg hx.1), ofReal_le_iff_le_toReal hb]
    · rw [toReal_ofReal_eq_iff]
      exact (le_trans toReal_nonneg hx.1)

-- sanity check: this measure is what you expect
example : volume (Set.Icc (3 : ℝ≥0∞) 42) = 39 := by
  rw [ENNReal.volume_val measurableSet_Icc]
  rw [ENNReal.toReal_Icc_eq_Icc (Ne.symm top_ne_ofNat) (Ne.symm top_ne_ofNat)]
  rw [toReal_ofNat, Real.volume_Icc, ofReal_eq_ofNat]
  norm_num

lemma integral_nnreal {f : ℝ≥0 → ℝ≥0∞} : ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ici (0 : ℝ), f x.toNNReal := by
  change ∫⁻ (x : ℝ≥0), f x = ∫⁻ (x : ℝ) in Ici 0, (f ∘ Real.toNNReal) x
  rw [← lintegral_subtype_comap measurableSet_Ici]
  simp
  rfl

lemma integral_nnreal' {f : ℝ≥0∞ → ℝ≥0∞} : ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ioi (0 : ℝ), f (.ofReal x) := sorry

-- TODO: prove these integral lemmas and name them properly
lemma todo' (f : ℝ≥0 → ℝ≥0∞) : ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ioi (0 : ℝ), f (Real.toNNReal x) := sorry

lemma todo'' (f : ℝ → ℝ≥0∞) : ∫⁻ x : ℝ≥0, f (x.toReal) = ∫⁻ x in Ioi (0 : ℝ), f x := sorry

-- TODO: lemmas about interaction with the Bochner integral
