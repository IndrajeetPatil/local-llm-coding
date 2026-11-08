# Local validation

Validated on 2026-11-08 with the latest Homebrew releases. These are checks
performed on the local Mac, not hosted CI results or a benchmark of general
coding ability.

| Component | Observed value |
| --- | --- |
| Hardware | Apple M1, arm64, 8 GiB unified memory |
| macOS | 27.0.1 |
| Homebrew | 7.0.12 |
| Ollama | 0.40.15, installed through Homebrew with MLX dependencies |
| Copilot CLI in the isolated offline home | 1.0.107 |
| jq | 1.8.2 |
| Base model | `qwen3.5:4b`, 4.5B parameters, `nvfp4` |
| Derived model | `local-coding-qwen3.5-4b-32768` |
| Runtime context | 32,768 tokens, confirmed by `ollama ps` |
| Copilot token budgets | 24,576 prompt / 4,096 output |
| Downloaded model storage | Approximately 3.7 GiB; derived model shares the weight blobs |
| Loaded model allocation | `ollama ps` reported 8.5–8.8 GB, 100% GPU, MLX runner, during the coding test |
| API listener | `127.0.0.1:11434` |

## Checks completed

- Downloaded the 4B model; Ollama verified its SHA-256 digest before writing
  the manifest.
- Ran `make setup`; repeated preparation reused the downloaded model layers.
- Ran `make verify` successfully in 2 minutes 46 seconds. The direct API
  returned exactly `MAKEFILE_OLLAMA_OK`, and Copilot executed its native
  `create` tool, wrote the exact probe bytes, and returned exactly
  `MAKEFILE_COPILOT_OK`.
- Ran that verification with deliberately conflicting `OLLAMA_HOST`,
  `COPILOT_PROVIDER_WIRE_MODEL`, and `COPILOT_PROVIDER_MODEL_ID` values. It
  still used the configured local endpoint and model successfully.
- Confirmed that model and Copilot state are stored outside the repository,
  and that the isolated Copilot home has mode `0700`.
- Confirmed that invalid token budgets, missing model state, and the 9B model
  on this 8 GiB machine produce failures with actionable messages.
- Checked generated recipe syntax with `make -n ... | zsh -n` and exercised
  help output with and without color.
- Stopped Ollama with `make stop` and confirmed its API stopped responding.
  Launched `make start` from a separate project directory; it restarted the
  service and reused the model download successfully.
- Used the normal Copilot tool definitions, with shell commands denied, to read
  a task file and create a Python `sum_even` function. The prompt named the
  `view` and `create` tools; the session used only those two tools and took
  2 minutes 41 seconds, including 81 seconds of initial prompt processing.
  After inspecting the generated source, ran six checks with Python 3.15.2
  covering empty input, odd-only input, mixed and negative values, duplicates,
  generators, and input preservation; all passed.

The normal system instructions and tool definitions occupied about 12.6K
tokens before the task itself (4,635 and 8,009 tokens). A 12,288-token prompt
budget exits before inference; the 24,576-token prompt budget and
32,768-token runtime context support the full session. `make verify` retains
the normal tool definitions to detect this kind of startup regression.

## Scope and limits

The 9B configuration is documented as an option for larger Macs and was not
run on this machine. Exact formatting can require explicit prompts; the
verification uses a simple marker without a trailing newline.

The 4B model prefers shell commands for reading files. With the same task but
a prompt that did not name the file tools, it made 54 denied shell calls over
14 minutes and never used `view`, so it did not complete the task. When shell
access is denied, name Copilot's file tools, such as `view` and `create`, in
the prompt.

Offline provider routing and local inference were checked. No operating-system
network sandbox or packet-level network audit was performed. Interactive shell
tools remain subject to the permissions granted by the user.
