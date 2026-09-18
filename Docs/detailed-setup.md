# Detailed setup: Ollama with GitHub Copilot CLI

[Back to the quick start](../README.md)

## Architecture and model sizing

Copilot CLI supplies the interactive coding agent and tools. Ollama runs the
model on the Mac and exposes an OpenAI-compatible Chat Completions endpoint at
`http://127.0.0.1:11434/v1`. The `openai` provider setting selects this protocol;
it does not send requests to OpenAI.

The default model is `qwen3.5:4b`, a quantized, approximately 3.4 GB model with
tool-calling and streaming support. It is a practical starting point for an
8 GiB Apple Silicon Mac. Model weights, inference buffers, context caches,
macOS, and other apps share memory, so the download size is not the total RAM
requirement. Close heavy applications if the machine starts swapping.

The original guide described a 32 GiB M2 Pro running `qwen3.5:9b`; those were
not the specifications of the Mac used for this repository's current validation.
The 9B model remains an explicit option for machines with more memory. See
[the validation record](validation.md) for the configuration actually tested.

Check a machine's capacity with:

```bash
uname -m
sysctl -n machdep.cpu.brand_string
sysctl -n hw.memsize
df -h "$HOME"
```

`hw.memsize` is in bytes; divide by 1,073,741,824 for GiB.

GitHub recommends at least 128K context for the best Copilot CLI experience.
This setup deliberately uses a smaller runtime context to fit local hardware.
It is intended for focused tasks and short sessions. A passing file-tool probe
does not establish that a small model can reliably perform complex refactors.

## Setup and configuration

```bash
make setup
make verify
make start
```

`make setup` checks capacity, installs missing Ollama, Copilot CLI, and `jq`
through Homebrew, starts the Ollama login service, and downloads the base model.
It then creates a derived model containing an explicit `num_ctx` parameter.
The derived model shares the base model's weight blobs; it does not download
another copy of the weights.

| Make variable | Default | Meaning |
| --- | --- | --- |
| `MODEL` | `qwen3.5:4b` | Base model to download. |
| `CONTEXT_TOKENS` | `32768` | Ollama runtime context, set with a generated Modelfile. |
| `LOCAL_MODEL` | `local-coding-qwen3.5-4b-32768` | Derived model name passed to Copilot. |
| `PROMPT_TOKENS` | `24576` | Copilot prompt budget. |
| `OUTPUT_TOKENS` | `4096` | Copilot response budget. |
| `OLLAMA_URL` | `http://127.0.0.1:11434` | API endpoint used by both curl and the Ollama CLI. |
| `MIN_MEMORY_GIB` | `8` | Minimum physical memory before setup. |
| `MIN_DISK_GIB` | `10` | Free disk headroom for downloads and macOS swap. |
| `START_TIMEOUT` | `60` | Seconds to wait for service readiness. |
| `VERIFY_TIMEOUT` | `300` | Direct API inference timeout in seconds. |
| `COPILOT_LOCAL_HOME` | `~/.copilot-local-offline` | Isolated Copilot settings and session data. |
| `COPILOT_ARGS` | Empty | Optional extra arguments for `make start`. |

The prompt and response budgets must fit within `CONTEXT_TOKENS`. The defaults
also leave 4,096 tokens of headroom. Copilot's default tools and instructions
alone consumed about 12.5K tokens in validation, so a 12K prompt budget cannot
start an ordinary coding session. Copilot's token limits alone do **not**
configure Ollama's runtime context. The OpenAI-compatible API does not support
`options.num_ctx`; setting it there has no effect. That is why the Makefile
creates a derived model using `PARAMETER num_ctx`.

The equivalent manual model configuration is:

```bash
ollama pull qwen3.5:4b
printf 'FROM qwen3.5:4b\nPARAMETER num_ctx 32768\n' > /tmp/local-coding.Modelfile
ollama create local-coding-qwen3.5-4b-32768 -f /tmp/local-coding.Modelfile
rm /tmp/local-coding.Modelfile
```

For the optional 9B model on a larger Mac, use the overrides in the root README.
Keep overrides consistent between Make invocations. Custom `OLLAMA_URL` values
must refer to an already configured local Ollama server: changing the client
URL does not change the Homebrew service's listening address. This workflow
expects a per-user Homebrew Ollama service, not Docker or the Ollama desktop app.

### Copilot provider settings

The Makefile scopes these settings to the child Copilot process:

| Setting | Purpose |
| --- | --- |
| `COPILOT_PROVIDER_TYPE=openai` | Select the OpenAI-compatible adapter. |
| `COPILOT_PROVIDER_BASE_URL=$(OLLAMA_URL)/v1` | Route inference to Ollama. |
| `COPILOT_PROVIDER_WIRE_API=completions` | Use Chat Completions. |
| `COPILOT_PROVIDER_TRANSPORT=http` | Avoid inherited WebSocket settings. |
| `COPILOT_MODEL=$(LOCAL_MODEL)` | Use the model with the configured context. |
| `COPILOT_PROVIDER_MAX_PROMPT_TOKENS` / `COPILOT_PROVIDER_MAX_OUTPUT_TOKENS` | Set the client token budgets. |
| `COPILOT_OFFLINE=true` | Disable GitHub authentication, web tools, telemetry, and auto-update. |
| `COPILOT_HOME` | Isolate local sessions from normal user-level Copilot settings. |

Inherited provider credentials, headers, model-ID overrides, proxy settings,
and global allow-all permissions are cleared. OpenTelemetry, built-in MCP
servers, remote session export, and remote control are explicitly disabled.
The Makefile does not edit `~/.zshrc` or require a separate shell launcher.

To work in another project directory, use the absolute path to this Makefile:

```bash
cd /path/to/your/project
make -f /path/to/local-llm-coding/Makefile start
```

## Files and state outside this repository

| Location | Owner and purpose |
| --- | --- |
| `~/.ollama/models/` | Ollama model weights and manifests, including the derived model. |
| `~/.ollama/` | Other Ollama state; may contain local identity keys. |
| `~/.copilot-local-offline/` | Copilot configuration, sessions, and logs; created with mode `0700`. |
| `~/Library/LaunchAgents/sh.brew.ollama.plist` | Homebrew 7 login service definition. |
| `$(brew --prefix)/var/log/ollama.log` | Ollama service log. |
| Homebrew prefix | Installed Ollama, MLX dependencies, Copilot CLI, and jq. |
| System temporary directory | Generated Modelfile and verification probe, removed after use. |

These locations are not committed. The `.gitignore` also excludes common
credentials, model directories, logs, and session exports inside the checkout.
Inspect session logs carefully before sharing them: they may contain prompts.

`make check-state` validates binaries, private Copilot directory permissions,
the model directory, service definition, API health, base model, and derived
model context. Earlier Homebrew versions may name the service file
`homebrew.mxcl.ollama.plist`; override `OLLAMA_LAUNCH_AGENT` if appropriate.
`OLLAMA_MODELS_DIR` changes the expected path for the check only; it does not
relocate Ollama's storage. Configure custom storage in the service itself.

## Verification

`make verify` runs two checks:

1. Call Ollama's OpenAI-compatible endpoint and parse the JSON response with
   `jq`. The assistant content must exactly equal `MAKEFILE_OLLAMA_OK`; a token
   appearing only in reasoning or elsewhere in the JSON does not pass.
2. Start Copilot in a fresh temporary directory with its normal tool definitions
   and write permission for the absolute `probe.txt` path. Verify the
   file's exact marker bytes (without a newline) and the exact final assistant
   response `MAKEFILE_COPILOT_OK`, parsed from Copilot's JSON event output.

The Copilot probe disables custom instructions and automatic access to other
temporary paths. It explicitly denies shell tools and grants no URL or
unrestricted filesystem permissions. Keeping the normal tool definitions
ensures the test catches a prompt budget too small for an ordinary session.
It uses streaming through the same provider settings as interactive sessions.
The temporary file and directory are removed afterward. Copilot's session
records remain in the isolated home directory.

For a manual API check:

```bash
curl --noproxy '*' --max-time 300 -fsS \
  http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "local-coding-qwen3.5-4b-32768",
    "messages": [{"role": "user", "content": "Reply with exactly LOCAL_MODEL_OK"}],
    "stream": false,
    "max_tokens": 4096,
    "reasoning_effort": "none"
  }' | jq '.choices[0].message.content'
ollama ps
```

`ollama ps` reports the actual runtime context and CPU/GPU allocation. An empty
list means no model is currently loaded, which is normal after the idle timeout.

## Operations and troubleshooting

```bash
make status
make check-state
make stop
make setup
```

Stopping the Homebrew service unloads the model and unregisters login startup.
`make setup` or `make start` enables the login service again. To restart directly:

```bash
brew services restart ollama
```

### Slow responses or memory pressure

Close memory-heavy apps, keep prompts focused, and inspect `ollama ps` and
Activity Monitor. The first request loads the model and can take longer.
With the full Copilot tool set, initial prompt processing can take several
minutes on an 8 GiB M1 using both CPU and GPU.
Reducing the context requires reducing the Copilot prompt/output budgets too.
Do not bypass the memory check to run the 9B model on an 8 GiB Mac.

### Tool calls appear as JSON text

Text such as `{"name":"create", ...}` is not a tool execution. Run
`make verify`; it fails unless Copilot actually creates the probe file. A
model's advertised tool capability does not guarantee reliable agent behavior.

### Context-length errors

Check the derived model's parameters and loaded context:

```bash
ollama show local-coding-qwen3.5-4b-32768 --parameters
ollama ps
```

Use the same overrides for `make setup`, `make verify`, and `make start`.
Start a new session or reduce attached context when the conversation grows.

### Service or API unavailable

Run `brew services info ollama` and inspect the Ollama log. The Makefile waits
up to `START_TIMEOUT` for startup and bypasses proxies for local API checks.
If another Ollama installation owns port 11434, resolve that conflict before
using this Homebrew-managed workflow.

### Remove downloaded software

With Ollama still running, use `ollama rm` with the specific derived and base
model names you want to remove. Then run `make stop` and `brew uninstall ollama`.
Keep unrelated models and normal Copilot state if you still use them.

## Security and privacy

Inference uses the loopback Ollama endpoint. Copilot offline mode prevents its
GitHub service calls; no provider API key or GitHub login is needed. Initial
installation and model pulls require the internet. This setup does not install
an operating-system network sandbox or firewall.

Interactive sessions retain Copilot's normal tool permission prompts. Approved
shell commands and project-provided integrations can independently access files
and the network. Review those permissions and generated code before use. The
restricted verification probe establishes connectivity and basic tool execution,
not comprehensive model quality or network-isolation guarantees.

## References

- [GitHub: Using your own LLM models in Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models)
- Installed CLI references: `copilot help providers`, `copilot help environment`, `copilot help permissions`
- [Ollama: OpenAI compatibility and context configuration](https://docs.ollama.com/api/openai-compatibility)
- [Ollama: Context length](https://docs.ollama.com/context-length)
- [Ollama model library: Qwen3.5](https://ollama.com/library/qwen3.5)
