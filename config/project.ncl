# MegaDog Project Configuration (Nickel)
# RSR Compliant - Type-safe configuration

let Project = {
  name | String,
  version | String,
  description | String,
  license | String,
  repository | String,

  maintainers | Array String,

  # RSR compliance markers
  rsr | {
    compliant | Bool,
    version | String,
    container_runtime | String,
    vcs | String,
  },
}

let Environment = {
  name | String,
  blockchain | {
    network | String,
    chain_id | Number,
    rpc_url | String,
    explorer_url | String,
  },
  server | {
    host | String,
    port | Number,
    log_level | String,
  },
}

in {
  project | Project = {
    name = "megadog",
    version = "0.1.0",
    description = "Ethical merge game with Mandelbrot dogtags - no scams, just math",
    license = "AGPL-3.0",
    repository = "https://gitlab.com/megadog/megadog",

    maintainers = [
      "MegaDog Team <team@megadog.example>",
    ],

    rsr = {
      compliant = true,
      version = "1.0",
      container_runtime = "podman",
      vcs = "gitlab",
    },
  },

  environments = {
    development | Environment = {
      name = "development",
      blockchain = {
        network = "localhost",
        chain_id = 31337,
        rpc_url = "http://localhost:8545",
        explorer_url = "",
      },
      server = {
        host = "127.0.0.1",
        port = 8080,
        log_level = "debug",
      },
    },

    testnet | Environment = {
      name = "testnet",
      blockchain = {
        network = "polygon-amoy",
        chain_id = 80002,
        rpc_url = "https://rpc-amoy.polygon.technology",
        explorer_url = "https://amoy.polygonscan.com",
      },
      server = {
        host = "0.0.0.0",
        port = 8080,
        log_level = "info",
      },
    },

    production | Environment = {
      name = "production",
      blockchain = {
        network = "polygon",
        chain_id = 137,
        rpc_url = "https://polygon-rpc.com",
        explorer_url = "https://polygonscan.com",
      },
      server = {
        host = "0.0.0.0",
        port = 8080,
        log_level = "warn",
      },
    },
  },
}
