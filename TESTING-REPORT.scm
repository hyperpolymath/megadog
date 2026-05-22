;; SPDX-License-Identifier: MPL-2.0
;; MegaDog Testing Report - Guile Scheme Format
;; Generated: 2025-12-29 by Claude Code

(define testing-report
  '((metadata
      (version . "1.1")
      (generated . "2025-12-29")
      (project . "megadog")
      (generator . "claude-code"))

    (summary
      (status . "critical-issues-fixed")
      (total-issues . 10)
      (fixed-issues . 5)
      (remaining-issues . 5)
      (critical-issues . 0)  ; All 3 critical issues fixed
      (high-issues . 0)      ; Both high issues fixed
      (medium-issues . 3)
      (low-issues . 2)
      (estimated-remaining-hours . 2))

    (components
      ((name . "pony-server")
       (path . "server/src/*.pony")
       (files-analyzed . 10)
       (status . "issues-found")
       (issues . (1 2 3 7 8)))

      ((name . "vyper-contracts")
       (path . "contracts/*.vy")
       (files-analyzed . 2)
       (status . "issues-found")
       (issues . (4 5)))

      ((name . "kotlin-android")
       (path . "android/app/src/main/kotlin/")
       (files-analyzed . 3)
       (status . "issues-found")
       (issues . (6 9 10)))

      ((name . "nickel-config")
       (path . "config/*.ncl")
       (files-analyzed . 3)
       (status . "ok")
       (issues . ())))

    (issues
      ((id . 1)
       (severity . "fixed")
       (title . "Missing suspicious_pattern_threshold in GameConfig")
       (file . "server/src/config.pony")
       (line . 197)
       (description . "UserSession.is_suspicious() references config.suspicious_pattern_threshold but field is not defined")
       (impact . "compilation-failure")
       (fix . "Add suspicious_pattern_threshold: F64 to GameConfig class")
       (status . "FIXED - Added field with default value 0.95"))

      ((id . 2)
       (severity . "fixed")
       (title . "Duplicate field declaration in BlockMonitor")
       (file . "server/src/blockchain_client.pony")
       (lines . (189 233))
       (description . "_last_block is declared twice in BlockMonitor actor")
       (impact . "compilation-failure")
       (fix . "Remove duplicate declaration at line 233-235")
       (status . "FIXED - Removed duplicate, added update_last_block behavior"))

      ((id . 3)
       (severity . "fixed")
       (title . "Invalid self-reference in BlockMonitor callback")
       (file . "server/src/blockchain_client.pony")
       (lines . (222 230))
       (description . "Lambda captures self and accesses actor field, violating reference capabilities")
       (impact . "compilation-failure")
       (fix . "Refactor to use proper behavior callback pattern")
       (status . "FIXED - Capture last_block value instead of self"))

      ((id . 4)
       (severity . "fixed")
       (title . "Deprecated shift() function in MegaDog.vy")
       (file . "contracts/MegaDog.vy")
       (lines . (134 159))
       (description . "Uses deprecated shift() instead of >> and << operators")
       (impact . "deprecation-warning")
       (fix . "Replace shift(temp, -1) with temp >> 1")
       (status . "FIXED - Replaced with >> and << operators"))

      ((id . 5)
       (severity . "fixed")
       (title . "Deprecated shift() function in LogLib.vy")
       (file . "contracts/LogLib.vy")
       (lines . (49 75))
       (description . "Same deprecated shift() usage in library")
       (impact . "deprecation-warning")
       (fix . "Replace shift() with bitwise operators")
       (status . "FIXED - Replaced with >> and << operators"))

      ((id . 6)
       (severity . "medium")
       (title . "Missing Android MainActivity")
       (file . "android/app/src/main/kotlin/com/megadog/")
       (description . "No MainActivity.kt or AndroidManifest.xml found")
       (impact . "incomplete-build")
       (fix . "Add MainActivity and manifest files"))

      ((id . 7)
       (severity . "medium")
       (title . "Undefined U256 type in Pony")
       (file . "server/src/dog.pony")
       (lines . (14 151 160))
       (description . "U256 type may not be in standard library")
       (impact . "potential-compilation-failure")
       (fix . "Define U256 or use crypto primitives"))

      ((id . 8)
       (severity . "medium")
       (title . "Missing explicit Range import")
       (file . "server/src/dog.pony")
       (lines . (160 175))
       (description . "Range used without explicit import")
       (impact . "code-clarity")
       (fix . "Add explicit import for Range"))

      ((id . 9)
       (severity . "low")
       (title . "Blocking I/O in Kotlin coroutines")
       (file . "android/app/src/main/kotlin/com/megadog/game/GameClient.kt")
       (description . "Uses blocking Socket/PrintWriter instead of non-blocking I/O")
       (impact . "potential-thread-exhaustion")
       (fix . "Use java.nio or Ktor for non-blocking I/O"))

      ((id . 10)
       (severity . "low")
       (title . "WebSocket protocol mismatch")
       (file . "android/app/src/main/kotlin/com/megadog/game/GameClient.kt")
       (description . "Client uses raw TCP but server expects WebSocket frames")
       (impact . "protocol-mismatch")
       (fix . "Implement proper WebSocket framing")))

    (test-coverage
      ((module . "LogMath-Pony")
       (coverage-percent . 0)
       (missing-tests . ("ln_approx" "exp_approx" "add_logs edge cases")))

      ((module . "LogMath-Kotlin")
       (coverage-percent . 0)
       (missing-tests . ("precision boundaries" "overflow handling")))

      ((module . "LogMath-Vyper")
       (coverage-percent . 0)
       (missing-tests . ("precision tests" "gas optimization")))

      ((module . "DogStateManager")
       (coverage-percent . 0)
       (missing-tests . ("merge validation" "prestige mechanics" "concurrent access")))

      ((module . "AntiCheatEngine")
       (coverage-percent . 0)
       (missing-tests . ("suspicion scoring" "rate limiting" "bot detection")))

      ((module . "BatchAggregator")
       (coverage-percent . 0)
       (missing-tests . ("merkle tree" "compression" "flush timing")))

      ((module . "MandelbrotRenderer")
       (coverage-percent . 0)
       (missing-tests . ("shader compilation" "seed conversion" "export"))))

    (fixes-applied
      ((issue-ids . (1 2 3 4 5))
       (files-modified . ("server/src/config.pony"
                          "server/src/blockchain_client.pony"
                          "contracts/MegaDog.vy"
                          "contracts/LogLib.vy"))
       (description . "Fixed all critical and high priority issues")))

    (recommendations
      (p0-immediate
        ;; All P0 issues have been fixed
        ("All critical issues resolved"))

      (p1-short-term
        ("Add MainActivity.kt and AndroidManifest.xml"
         "Implement WebSocket protocol in GameClient"
         "Add U256 type definition"))

      (p2-medium-term
        ("Add unit tests for LogMath implementations"
         "Add integration tests for client-server"
         "Replace blocking I/O in Android"))

      (p3-long-term
        ("Migrate Android to Tauri 2.0 per RSR"
         "Add fuzzing for contract math"
         "Full CI pipeline")))

    (static-analysis
      ((language . "pony")
       (files . 10)
       (syntax-issues . 3)
       (refcap-issues . 1)
       (type-issues . 1))

      ((language . "vyper")
       (files . 2)
       (deprecation-warnings . 2)
       (security-issues . 0))

      ((language . "kotlin")
       (files . 3)
       (compile-issues . 0)
       (coroutine-issues . 1)
       (protocol-issues . 1))

      ((language . "nickel")
       (files . 3)
       (type-issues . 0)
       (validation . "passed")))

    (files-analyzed
      ;; Pony server files
      "server/src/main.pony"
      "server/src/dog.pony"
      "server/src/dog_manager.pony"
      "server/src/config.pony"
      "server/src/websocket_server.pony"
      "server/src/batch_aggregator.pony"
      "server/src/anti_cheat.pony"
      "server/src/blockchain_client.pony"
      "server/src/connection_manager.pony"
      "server/src/metrics.pony"

      ;; Vyper contracts
      "contracts/MegaDog.vy"
      "contracts/LogLib.vy"

      ;; Kotlin Android
      "android/app/src/main/kotlin/com/megadog/game/Dog.kt"
      "android/app/src/main/kotlin/com/megadog/game/GameClient.kt"
      "android/app/src/main/kotlin/com/megadog/renderer/MandelbrotRenderer.kt"

      ;; Nickel config
      "config/game.ncl"
      "config/project.ncl"
      "config/ci.ncl")))

;; Helper functions for querying the report
(define (get-critical-issues report)
  (filter (lambda (issue)
            (equal? (assoc-ref issue 'severity) "critical"))
          (assoc-ref report 'issues)))

(define (get-issues-by-file report file)
  (filter (lambda (issue)
            (equal? (assoc-ref issue 'file) file))
          (assoc-ref report 'issues)))

(define (get-component-status report component-name)
  (let ((component (find (lambda (c)
                           (equal? (assoc-ref c 'name) component-name))
                         (assoc-ref report 'components))))
    (if component
        (assoc-ref component 'status)
        #f)))

(define (estimated-fix-time report)
  (assoc-ref (assoc-ref report 'summary) 'estimated-fix-hours))

;; Export the report
testing-report
