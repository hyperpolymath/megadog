;;; ==================================================
;;; STATE.scm — MegaDog AI Conversation Checkpoint
;;; ==================================================
;;;
;;; SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
;;; Copyright (c) 2025 MegaDog Contributors
;;;
;;; STATEFUL CONTEXT TRACKING ENGINE
;;; Version: 2.0
;;;
;;; CRITICAL: Download this file at end of each session!
;;; At start of next conversation, upload it.
;;; Do NOT rely on ephemeral storage to persist.
;;;
;;; ==================================================

(define state
  '((metadata
      (format-version . "2.0")
      (schema-version . "2025-12-08")
      (created-at . "2025-12-08T00:00:00Z")
      (last-updated . "2025-12-08T00:00:00Z")
      (generator . "Claude/STATE-system"))

    ;; =========================================================
    ;; USER CONTEXT
    ;; =========================================================
    (user
      (name . "hyperpolymath")
      (roles . ("founder" "architect"))
      (preferences
        (languages-preferred . ("Pony" "Kotlin" "Vyper" "Nix"))
        (languages-avoid . ("JavaScript" "Solidity"))
        (tools-preferred . ("GitLab" "Podman" "Nix" "Nickel"))
        (values . ("RSR-compliance" "memory-safety" "anti-scam" "beautiful-math"))))

    ;; =========================================================
    ;; SESSION CONTEXT
    ;; =========================================================
    (session
      (conversation-id . "megadog-init-2025-12-08")
      (started-at . "2025-12-08T00:00:00Z")
      (messages-used . 1)
      (messages-remaining . 99)
      (token-limit-reached . #f))

    ;; =========================================================
    ;; CURRENT FOCUS
    ;; =========================================================
    (focus
      (current-project . "MegaDog")
      (current-phase . "foundation-to-mvp")
      (deadline . #f)
      (blocking-projects . ()))

    ;; =========================================================
    ;; CURRENT POSITION
    ;; =========================================================
    (position
      (summary . "Foundation complete, skeleton code in place, route to MVP requires integration work")

      (completed
        ("Vyper smart contract with logarithmic storage"
         "Pony server actor architecture skeleton"
         "Android/Kotlin client skeleton"
         "Mandelbrot renderer GPU shaders"
         "Nix flake development environment"
         "Nickel type-safe configuration"
         "RSR-compliant project structure"
         "GitHub CI/CD workflows (CodeQL, dependabot)"
         "Formal proofs library for logarithmic storage"))

      (in-progress
        ("Server WebSocket implementation"
         "Client-server protocol integration"
         "Contract deployment scripts"))

      (not-started
        ("Test suites (Pony, contract, integration)"
         "Android UI beyond skeleton"
         "Testnet deployment"
         "NFT metadata + IPFS integration"
         "Wallet connection (WalletConnect/MetaMask)")))

    ;; =========================================================
    ;; PROJECT CATALOG
    ;; =========================================================
    (projects
      ;; Main project
      ((name . "MegaDog MVP")
       (status . "in-progress")
       (completion . 35)
       (category . "game")
       (phase . "integration")
       (dependencies . ())
       (blockers . ("nix-vyper-hash" "missing-tests"))
       (next . ("Fix Vyper hash in flake.nix"
                "Implement WebSocket message handlers"
                "Create contract deployment scripts"
                "Write unit tests for Pony server"))
       (chat-reference . #f)
       (notes . "Core architecture complete, need to wire components together"))

      ;; Sub-components
      ((name . "Vyper Contract")
       (status . "in-progress")
       (completion . 85)
       (category . "blockchain")
       (phase . "testing")
       (dependencies . ())
       (blockers . ("needs-testnet-deploy"))
       (next . ("Deploy to Mumbai testnet"
                "Write pytest test suite"
                "Verify on Polygonscan"))
       (chat-reference . #f)
       (notes . "Contract code complete, logarithmic math tested in proofs, awaiting deployment"))

      ((name . "Pony Server")
       (status . "in-progress")
       (completion . 40)
       (category . "backend")
       (phase . "implementation")
       (dependencies . ())
       (blockers . ())
       (next . ("Complete WebSocketServer actor"
                "Implement DogStateManager logic"
                "Wire up BatchAggregator to blockchain"
                "Add rate limiting in AntiCheatEngine"))
       (chat-reference . #f)
       (notes . "Actor structure in place, need to implement message handling"))

      ((name . "Android Client")
       (status . "in-progress")
       (completion . 30)
       (category . "frontend")
       (phase . "implementation")
       (dependencies . ("Pony Server"))
       (blockers . ("server-incomplete"))
       (next . ("Build merge UI"
                "Integrate MandelbrotRenderer"
                "Add wallet connection"
                "Implement local caching"))
       (chat-reference . #f)
       (notes . "GameClient and renderer done, need UI and wallet integration"))

      ((name . "DevOps & CI")
       (status . "in-progress")
       (completion . 50)
       (category . "infrastructure")
       (phase . "implementation")
       (dependencies . ())
       (blockers . ("vyper-nix-hash"))
       (next . ("Fix flake.nix Vyper SHA256"
                "Create deploy.sh script"
                "Create verify.sh script"
                "Test container build"))
       (chat-reference . #f)
       (notes . "Nix flake has placeholder hash, needs fixing")))

    ;; =========================================================
    ;; ISSUES / BLOCKERS
    ;; =========================================================
    (issues
      ((id . "nix-vyper-hash")
       (severity . "critical")
       (component . "flake.nix")
       (description . "Vyper package SHA256 is placeholder 'AAAA...', nix build will fail")
       (resolution . "Run nix-prefetch-url or use fetchPypi with correct hash")
       (line-ref . "flake.nix:92"))

      ((id . "missing-deploy-scripts")
       (severity . "high")
       (component . "scripts/")
       (description . "deploy.sh and verify.sh referenced in justfile but don't exist")
       (resolution . "Create deployment scripts for Mumbai/Polygon"))

      ((id . "no-tests")
       (severity . "high")
       (component . "tests/")
       (description . "No test suites exist for any component")
       (resolution . "Write pytest for contracts, ponytest for server"))

      ((id . "websocket-incomplete")
       (severity . "medium")
       (component . "server/src/websocket_server.pony")
       (description . "WebSocket handler logic not implemented")
       (resolution . "Implement message parsing and routing"))

      ((id . "wallet-integration")
       (severity . "medium")
       (component . "android/")
       (description . "No wallet connection implemented")
       (resolution . "Add WalletConnect or MetaMask integration")))

    ;; =========================================================
    ;; QUESTIONS FOR USER
    ;; =========================================================
    (questions
      ((id . 1)
       (priority . "high")
       (question . "What's the priority: local playability (server+client) or blockchain integration first?")
       (options . ("Local first - merge loop without blockchain"
                   "Blockchain first - deploy contracts, add wallet"
                   "Parallel - both simultaneously"))
       (impact . "Determines next sprint focus"))

      ((id . 2)
       (priority . "high")
       (question . "Target network for MVP deployment?")
       (options . ("Polygon Mumbai testnet"
                   "Polygon mainnet"
                   "Local hardhat/anvil"))
       (impact . "Affects gas cost testing and deployment scripts"))

      ((id . 3)
       (priority . "medium")
       (question . "Wallet integration preference?")
       (options . ("WalletConnect v2"
                   "MetaMask SDK"
                   "Custom embedded wallet"
                   "Defer to post-MVP"))
       (impact . "Significant implementation effort"))

      ((id . 4)
       (priority . "medium")
       (question . "MVP scope - minimal feature set?")
       (options . ("Core only: mint + merge + view fractal"
                   "Plus prestige: add prestige reset"
                   "Full: all features including batch commits"))
       (impact . "Timeline and complexity"))

      ((id . 5)
       (priority . "low")
       (question . "NFT metadata hosting?")
       (options . ("IPFS via Pinata"
                   "Arweave"
                   "On-chain SVG"
                   "Centralized CDN initially"))
       (impact . "Affects decentralization and costs")))

    ;; =========================================================
    ;; ROUTE TO MVP v1
    ;; =========================================================
    (mvp-roadmap
      (target-version . "1.0.0")
      (definition . "Playable merge game with on-chain ownership and Mandelbrot dogtags")

      (milestones
        ((name . "M1: Local Playable")
         (completion . 30)
         (deliverables . ("Pony server runs and accepts connections"
                          "Android app connects and displays dogs"
                          "Merge operation works locally"
                          "Mandelbrot renders for each dog"))
         (blockers . ("websocket-incomplete")))

        ((name . "M2: Contract Deployed")
         (completion . 0)
         (deliverables . ("Vyper contract deployed to Mumbai"
                          "Contract verified on explorer"
                          "Test transactions successful"))
         (blockers . ("missing-deploy-scripts" "nix-vyper-hash")))

        ((name . "M3: Full Integration")
         (completion . 0)
         (deliverables . ("Server submits batch commits"
                          "Client shows blockchain state"
                          "Wallet connection works"
                          "Gas costs measured"))
         (blockers . ("wallet-integration")))

        ((name . "M4: Polish & Release")
         (completion . 0)
         (deliverables . ("UI polish"
                          "Error handling"
                          "Loading states"
                          "Analytics/transparency dashboard"))
         (blockers . ()))))

    ;; =========================================================
    ;; LONG-TERM ROADMAP
    ;; =========================================================
    (roadmap
      ((version . "1.0.0")
       (codename . "First Bark")
       (status . "in-progress")
       (features . ("Core merge loop"
                    "Mandelbrot dogtags"
                    "On-chain ownership"
                    "Batch commits"
                    "Single-player")))

      ((version . "1.1.0")
       (codename . "Prestige Pup")
       (status . "planned")
       (features . ("Prestige system (milkshake blender)"
                    "Permanent multipliers"
                    "Achievement system"
                    "Offline progress")))

      ((version . "1.2.0")
       (codename . "Gallery Dog")
       (status . "planned")
       (features . ("NFT export to OpenSea"
                    "4K wallpaper generation"
                    "IPFS metadata storage"
                    "Trading marketplace")))

      ((version . "2.0.0")
       (codename . "Pack Hunt")
       (status . "concept")
       (features . ("Multiplayer dog battles"
                    "Guild system"
                    "Seasonal events"
                    "Leaderboards")))

      ((version . "2.1.0")
       (codename . "Cross-Breed")
       (status . "concept")
       (features . ("iOS port"
                    "Desktop client"
                    "Cross-platform sync"
                    "Web client"))))

    ;; =========================================================
    ;; CRITICAL NEXT ACTIONS
    ;; =========================================================
    (critical-next
      ;; Top 5 immediate actions, prioritized
      ("Fix Vyper SHA256 hash in flake.nix to unblock nix builds"
       "Create scripts/deploy.sh for Mumbai testnet deployment"
       "Implement WebSocket message handlers in Pony server"
       "Write pytest tests for MegaDog.vy contract"
       "Deploy contract to Mumbai and verify"))

    ;; =========================================================
    ;; HISTORY (for velocity tracking)
    ;; =========================================================
    (history
      (snapshots
        ((timestamp . "2025-12-08T00:00:00Z")
         (projects
           ((name . "MegaDog MVP") (completion . 35))
           ((name . "Vyper Contract") (completion . 85))
           ((name . "Pony Server") (completion . 40))
           ((name . "Android Client") (completion . 30))
           ((name . "DevOps & CI") (completion . 50))))))

    ;; =========================================================
    ;; FILES CONTEXT
    ;; =========================================================
    (files-created-this-session
      ("STATE.scm"))

    (files-modified-this-session
      ())

    ;; =========================================================
    ;; TECHNICAL DEBT
    ;; =========================================================
    (tech-debt
      ((id . "placeholder-hash")
       (location . "flake.nix:92")
       (description . "Vyper SHA256 placeholder")
       (effort . "low")
       (risk . "high"))

      ((id . "simplified-log-math")
       (location . "contracts/MegaDog.vy:163-178")
       (description . "_add_logs uses simplified approximation, not precise")
       (effort . "medium")
       (risk . "low")))

    ;; =========================================================
    ;; CONTEXT NOTES
    ;; =========================================================
    (context-notes . "
MegaDog is an ethical remake of predatory merge games.
Key innovation: logarithmic storage reduces gas costs by ~30%.
Stack: Pony (server) + Kotlin (Android) + Vyper (blockchain).
All RSR compliant: memory-safe, Nix, Podman, Nickel configs.
The game generates unique 3D Mandelbulb fractals as 'dogtags'.
No fake money promises - pure math entertainment.
")))

;;; ==================================================
;;; QUICK REFERENCE
;;; ==================================================
;;;
;;; Key files:
;;;   contracts/MegaDog.vy          - Smart contract (85% done)
;;;   server/src/main.pony          - Server entry point
;;;   server/src/websocket_server.pony - Needs implementation
;;;   android/app/.../GameClient.kt - Client networking
;;;   android/app/.../MandelbrotRenderer.kt - GPU rendering
;;;   flake.nix                     - Nix dev environment (HAS BUG)
;;;   config/game.ncl               - Game config
;;;
;;; Build commands:
;;;   nix develop                   - Enter dev shell
;;;   just build-all                - Build everything
;;;   just contracts-compile        - Compile Vyper
;;;   just container-run            - Run server
;;;
;;; Immediate blockers:
;;;   1. flake.nix:92 - Vyper SHA256 is "AAAA..." placeholder
;;;   2. scripts/deploy.sh - Missing file
;;;   3. No tests exist
;;;
;;; ==================================================
;;; END STATE.scm
;;; ==================================================
