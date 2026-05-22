-- SPDX-License-Identifier: MPL-2.0
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
