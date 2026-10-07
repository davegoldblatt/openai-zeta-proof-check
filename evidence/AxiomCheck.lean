import OAI.NumberTheory.DirichletL.Nonvanishing

example {s : ℂ} (hs : (7 / 8 : ℝ) < s.re) : _root_.riemannZeta s ≠ 0 :=
  OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re hs

#print axioms OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re
