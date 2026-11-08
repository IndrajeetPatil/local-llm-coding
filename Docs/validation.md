# Local validation

## Re-verification on 2026-11-08

`make setup` and `make verify` passed with the latest Homebrew releases on the
same Apple M1 with 8 GiB unified memory. The interactive coding session below
was not repeated.

| Component | Observed value |
| --- | --- |
| macOS | 27.0.1 |
| Homebrew | 7.0.12 |
| Ollama | 0.40.15 |
| Copilot CLI in the isolated offline home | 1.0.107 |
| jq | 1.8.2 |
| Base model | `qwen3.5:4b`, 4.7B parameters, `Q4_K_M` |
| `make verify` duration | 8 minutes 56 seconds |

Copilot CLI 1.0.107 rejects the removed `--no-remote` flag, so the launcher
no longer passes it. `qwen3.5` remains the newest Qwen family on Ollama with
4B and 9B sizes; `qwen3.6` and `qwen3.8` start at 27B.

## Initial validation on 2026-09-18

These are checks performed on the local Mac, not hosted CI results or a
benchmark of general coding ability.

| Component | Observed value |
| --- | --- |
| Hardware | Apple M1, arm64, 8 GiB unified memory |
| macOS | 26.6.2 |
| Homebrew | 7.0.3 |
| Ollama | 0.34.2, installed through Homebrew with MLX dependencies |
| Copilot CLI in the isolated offline home | 1.0.78 |
| jq | 1.8.2 |
| Base model | `qwen3.5:4b`, 4.7B parameters, `Q4_K_M` |
| Derived model | `local-coding-qwen3.5-4b-32768` |
| Runtime context | 32,768 tokens, confirmed by `ollama ps` and `/api/ps` |
| Copilot token budgets | 24,576 prompt / 4,096 output |
| Downloaded model storage | Approximately 3.2 GiB; derived model shares the weight blobs |
| Loaded model allocation | Approximately 4.4 GB, 31% CPU / 69% GPU during the coding test |
| API listener | `127.0.0.1:11434` |

The ordinary `copilot --version` reported 1.0.80 through the normal user's
update cache. The isolated offline launcher used 1.0.78; the Makefile reports
the version from that same isolated environment.

### Checks completed

- Installed Ollama and downloaded the 4B model; Ollama verified its SHA-256
  digest before writing the manifest.
- Ran `make setup`; repeated preparation reused the downloaded model layers.
- Ran `make verify` successfully. The direct API returned exactly
  `MAKEFILE_OLLAMA_OK`, and Copilot executed its native `create` tool, wrote
  the exact probe bytes, and returned exactly `MAKEFILE_COPILOT_OK`.
- Ran the final verification with deliberately conflicting `OLLAMA_HOST`,
  `COPILOT_PROVIDER_WIRE_MODEL`, and `COPILOT_PROVIDER_MODEL_ID` values. It
  still used the configured local endpoint and model successfully.
- Confirmed that model and Copilot state are stored outside the repository,
  and that the isolated Copilot home has mode `0700`.
- Confirmed that invalid token budgets, missing model state, and the 9B model
  on this 8 GiB machine produce failures with actionable messages.
- Checked generated recipe syntax with `make -n ... | zsh -n` and exercised
  help output with and without terminal/color handling.
- Stopped Ollama with `make stop` and confirmed its API stopped responding.
  Launched `make start` from a separate project directory; it restarted the
  service and reused the model download successfully.
- Used the normal Copilot tool definitions to read a task file and create a
  Python `sum_even` function. After inspecting the generated source, ran six
  checks with Python 3.14.7 covering empty input, odd-only input, mixed and
  negative values, duplicates, generators, and input preservation; all passed.
  Copilot also attempted an unrequested shell test, which the explicit shell
  denial blocked. The CLI finished successfully. This read/create session took
  7 minutes 55 seconds, including initial prompt processing.

The normal tool definitions and instructions occupied about 12.5K tokens before
the task itself. A trial 12,288-token prompt budget exited before inference;
the final 24,576-token prompt budget and 32,768-token runtime context supported
the full session. `make verify` retains the normal tool definitions to detect
this kind of startup regression.

### Scope and limits

The 9B configuration is documented as an option for larger Macs and was not
run on this machine. The 4B model uses both CPU and GPU under the observed
memory conditions, so allow time for prompt processing and avoid large tasks.
Exact formatting can require explicit prompts; the verification uses a simple
marker without a trailing newline.

Offline provider routing and local inference were checked. No operating-system
network sandbox or packet-level network audit was performed. Interactive shell
tools remain subject to the permissions granted by the user.
