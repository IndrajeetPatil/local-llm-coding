# Local LLM coding with GitHub Copilot CLI

Run Qwen3.5 locally on an Apple Silicon Mac with Ollama and use it from GitHub
Copilot CLI. The Makefile installs missing tools, downloads the model, sets its
context window, and verifies inference and a real file-tool call.

## Requirements

- Apple Silicon Mac with [Homebrew](https://brew.sh)
- At least 8 GiB unified memory and 10 GiB free disk for the default 4B model
- Internet access for the initial software and model downloads

The default is `qwen3.5:4b` (about 3.4 GB) with a 32,768-token runtime context.
No model-provider API key or GitHub login is required for local inference.

> [!NOTE]
> **Expect slow initial responses on an 8 GiB Mac.** Our M1 read-and-create
> coding test took **7 minutes 55 seconds**. The model was split across CPU and
> GPU, and Copilot's default instructions and tools already occupied about
> 12.5K tokens before the task. This is one [measured run](Docs/validation.md),
> not a prediction for every prompt or Mac.

> [!TIP]
> To reduce waiting:
>
> - Quit unused RAM-heavy apps, virtual machines, and containers before starting.
>   This can help when memory pressure or swapping is high; it is not a
>   guaranteed speedup, and we have not benchmarked the difference.
> - Continue in the same Copilot session for related work and avoid restarting
>   Ollama between prompts. Ollama normally keeps the model loaded for five
>   minutes after a request, avoiding another model load during that time.
> - Keep tasks focused and attach only relevant files. This reduces added
>   context, although Copilot's initial instructions and tools still have a cost.
> - Check **Activity Monitor → Memory → Memory Pressure** and `make status`.
>   See [performance troubleshooting](Docs/detailed-setup.md#slow-responses-or-memory-pressure)
>   for interpreting the results and considering smaller models or more RAM.

## Quick start

```bash
git clone https://github.com/IndrajeetPatil/local-llm-coding.git
cd local-llm-coding
make setup
make verify
make start
```

The repository is private; cloning it requires GitHub access. `make start`
opens Copilot CLI using the local model. Exit Copilot from its UI when finished,
then run `make stop` to stop Ollama and disable its automatic startup at login.

## Commands

| Command | Purpose |
| --- | --- |
| `make setup` | Install missing tools, start Ollama, download and configure the model. |
| `make verify` | Check the API response and Copilot's ability to create a probe file. |
| `make start` | Prepare Ollama and open Copilot CLI with the local model. |
| `make stop` | Stop Ollama and unregister its Homebrew login service. |
| `make status` | Show service, API, downloaded models, and GPU/context status. |
| `make check-state` | Check required external files, tools, service, and model configuration. |
| `make help` | Show targets and defaults. |

Set `NO_COLOR=1` or `COLOR=never` for plain output.

## Local inference architecture

![Local inference: Copilot CLI sends Chat Completions to Ollama over loopback;
Qwen3.5 runs on the Mac's shared CPU/GPU memory. Responses and proposed tool
calls return to Copilot, which executes permission-controlled file tools.](Docs/images/local-inference.png)

`make start` launches Copilot CLI → loopback Ollama API → local Qwen3.5.
Responses return through Ollama to Copilot; Copilot controls tool execution
against project files. Inference can use both CPU and GPU.

### From model response to local action

![Local response workflow: Qwen3.5 generates text or a tool proposal; Ollama
encodes it as OpenAI-compatible Chat Completions; Copilot assembles the response,
displays text, checks tool permissions, and returns tool results for another
inference turn.](Docs/images/response-workflow.png)

Ollama provides the shared message format that Copilot understands. Interactive
responses stream as server-sent events (SSE) carrying JSON deltas; Copilot
assembles text and structured tool calls. Text appears in the terminal. Tool
calls pass through Copilot's permission checks before execution; their results
return in the conversation for another local inference turn. This can repeat
before the final reply. A denied tool does not execute, and text that merely
looks like a tool call does not execute either.

See [response handling and the wire format](Docs/detailed-setup.md#response-handling-and-the-wire-format)
for the fields and the distinction between streaming and the direct API check.

Provider settings apply only to the Copilot process started by Make. It uses
offline mode, disabled telemetry and built-in MCP servers, and a separate
configuration directory. Normal `copilot` settings remain available to normal
sessions. Commands you approve inside Copilot can still access the network.

For a larger model on a Mac with at least 16 GiB RAM, use the same overrides
for setup, verification, and each session:

```bash
export MODEL=qwen3.5:9b MIN_MEMORY_GIB=16 MIN_DISK_GIB=10
export CONTEXT_TOKENS=32768 PROMPT_TOKENS=24576 OUTPUT_TOKENS=4096
make setup
make verify
make start
```

See [the detailed guide](Docs/detailed-setup.md) for configuration, state stored
outside Git, manual API checks, troubleshooting, and the limits of verification.
The guide also illustrates the [setup stack](Docs/detailed-setup.md#setup-and-configuration)
and [verification harness](Docs/detailed-setup.md#verification).
