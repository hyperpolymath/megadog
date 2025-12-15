;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — megadog

(ecosystem
  (version "1.0.0")
  (name "megadog")
  (type "project")
  (purpose "*Ethical merge game with Mandelbrot dogtags - no scams, just math.*")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "*Ethical merge game with Mandelbrot dogtags - no scams, just math.*")
  (what-this-is-not "- NOT exempt from RSR compliance"))
