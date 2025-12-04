# MegaDog CI/CD Configuration (Nickel)
# GitLab CI pipeline definition (RSR: GitLab, never GitHub)

let Stage = [| 'validate, 'build, 'test, 'security, 'deploy |]

let Job = {
  stage | Stage,
  image | String,
  script | Array String,
  artifacts | { paths | Array String } | optional,
  rules | Array { if | String, when | String } | optional,
  needs | Array String | optional,
}

in {
  # GitLab CI configuration
  gitlab_ci = {
    stages = ["validate", "build", "test", "security", "deploy"],

    variables = {
      CONTAINER_RUNTIME = "podman",
      NIX_VERSION = "2.18",
    },

    jobs = {
      # Validation stage
      validate_nix | Job = {
        stage = 'validate,
        image = "nixos/nix:latest",
        script = [
          "nix flake check",
          "nixpkgs-fmt --check ./**/*.nix",
        ],
      },

      validate_nickel | Job = {
        stage = 'validate,
        image = "ghcr.io/tweag/nickel:latest",
        script = [
          "for f in config/*.ncl; do nickel typecheck \"$f\"; done",
        ],
      },

      validate_contracts | Job = {
        stage = 'validate,
        image = "vyperlang/vyper:latest",
        script = [
          "vyper contracts/MegaDog.vy",
        ],
      },

      # Build stage
      build_server | Job = {
        stage = 'build,
        image = "ponylang/ponyc:latest",
        script = [
          "cd server && ponyc -o ../build/bin -b megadog-server",
        ],
        artifacts = { paths = ["build/"] },
        needs = ["validate_nix"],
      },

      build_android | Job = {
        stage = 'build,
        image = "gradle:jdk17",
        script = [
          "cd android && ./gradlew assembleDebug",
        ],
        artifacts = { paths = ["android/app/build/outputs/"] },
        needs = ["validate_nix"],
      },

      build_container | Job = {
        stage = 'build,
        image = "quay.io/podman/stable:latest",
        script = [
          "podman build -t megadog-server:$CI_COMMIT_SHA -f containers/server.containerfile .",
          "podman save megadog-server:$CI_COMMIT_SHA -o megadog-server.tar",
        ],
        artifacts = { paths = ["megadog-server.tar"] },
        needs = ["build_server"],
      },

      # Test stage
      test_server | Job = {
        stage = 'test,
        image = "ponylang/ponyc:latest",
        script = [
          "cd server && ponyc --debug -o ../build/test && ../build/test/server",
        ],
        needs = ["build_server"],
      },

      test_contracts | Job = {
        stage = 'test,
        image = "vyperlang/vyper:latest",
        script = [
          "cd contracts && python -m pytest tests/ -v",
        ],
        needs = ["validate_contracts"],
      },

      # Security stage
      container_scan | Job = {
        stage = 'security,
        image = "cgr.dev/chainguard/grype:latest",
        script = [
          "grype megadog-server.tar",
        ],
        needs = ["build_container"],
      },

      # Deploy stage
      deploy_testnet | Job = {
        stage = 'deploy,
        image = "nixos/nix:latest",
        script = [
          "nix develop --command just contracts-deploy testnet",
        ],
        rules = [
          { if = "$CI_COMMIT_BRANCH == \"main\"", when = "manual" },
        ],
        needs = ["test_server", "test_contracts", "container_scan"],
      },
    },
  },
}
