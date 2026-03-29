-- SPDX-License-Identifier: PMPL-1.0-or-later
import Lake
open Lake DSL

package megadogProofs where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib LogarithmicStorage where
  srcDir := "."

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.16.0"
